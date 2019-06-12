--1.a

CREATE OR REPLACE TRIGGER control_peso_producto
BEFORE INSERT OR UPDATE ON PRODUCTO
FOR EACH ROW
DECLARE
    pesomax CAMION.PESOMAX%TYPE;
BEGIN
    SELECT MAX(pesomax) INTO pesomax FROM CAMION;
    IF(:NEW.peso > pesomax) THEN
        RAISE_APPLICATION_ERROR(-20000,'El peso de un producto no puede ser mayor al camion mas grande');
    END IF;
END;

CREATE OR REPLACE TRIGGER control_peso_camion
FOR UPDATE OR DELETE ON CAMION
COMPOUND TRIGGER
    pesoMax CAMION.PESOMAX%TYPE;
    productoPesoMax PRODUCTO.PESO%TYPE;
    AFTER STATEMENT IS
    BEGIN
        SELECT MAX(PESOMAX) INTO pesoMax FROM CAMION;
        SELECT MAX(PESO) INTO productoPesoMax FROM PRODUCTO;
        IF (productoPesoMax > pesoMax OR (pesoMax IS NULL AND productoPesoMax IS NOT NULL)) THEN
            RAISE_APPLICATION_ERROR(-20000,'El peso de un producto no puede ser mayor al camion mas grande');
        END IF;
    END AFTER STATEMENT;
END;


--1.b


--2.a

CREATE OR REPLACE TRIGGER control_precio_ruta
BEFORE INSERT ON RUTADIRECTA
FOR EACH ROW
DECLARE
    CURSOR PATHS IS
    SELECT * FROM RUTADIRECTA
    START WITH CIUDADINICIO = :NEW.CIUDADINICIO
    CONNECT BY NOCYCLE PRIOR CIUDADFIN = CIUDADINICIO;
    lowestP RUTADIRECTA.COSTO%TYPE;
    partialP RUTADIRECTA.COSTO%TYPE;
    value2check RUTADIRECTA.COSTO%TYPE;
    bif NUMBER(1);
    arrived NUMBER(1);
BEGIN
    lowestP := 0;
    partialP := 0;
    arrived := 0;
    FOR p IN PATHS LOOP
        IF arrived = 1 THEN
            arrived := 0;
            IF p.CIUDADINICIO = :NEW.CIUDADINICIO THEN
                partialP := 0;
            ELSE
                partialP := value2check;
            END IF;
        END IF;
        partialP := partialP + p.COSTO;
        IF p.CIUDADFIN = :NEW.CIUDADFIN THEN
            arrived := 1;
            IF partialP < lowestP OR lowestP = 0 THEN
                lowestP := partialP;
            END IF;
        ELSIF p.CIUDADINICIO <> :NEW.CIUDADINICIO THEN
            SELECT COUNT(*) INTO bif FROM RUTADIRECTA WHERE CIUDADINICIO = p.CIUDADINICIO;
            IF bif > 1 THEN
                value2check := partialP;
            END IF;
        END IF;
    END LOOP;
    IF :NEW.COSTO > lowestP AND lowestP > 0 THEN
        RAISE_APPLICATION_ERROR(-20001,'No puede agregar una ruta directa que cueste más que la menor compuesta');
    END IF;
END;

--2.b
CREATE OR REPLACE TRIGGER control_max_caminos
BEFORE INSERT ON RUTADIRECTA
FOR EACH ROW
DECLARE
    rowcount NUMBER;
    CURSOR ciudades IS
    SELECT DISTINCT CIUDADINICIO AS value FROM RUTADIRECTA;
BEGIN
    FOR ciudad IN CIUDADES LOOP
        SELECT COUNT(*) INTO rowcount FROM
            (SELECT CIUDADFIN, COUNT(CIUDADFIN) AS PATHS FROM (
                SELECT * FROM (
                    SELECT * FROM RUTADIRECTA
                    UNION
                    SELECT :NEW.CIUDADINICIO AS CIUDADINICIO, :NEW.CIUDADFIN AS CIUDADFIN, :NEW.COSTO AS COSTO FROM DUAL
                )
                START WITH CIUDADINICIO = ciudad.value
                CONNECT BY NOCYCLE PRIOR CIUDADFIN = CIUDADINICIO
            )GROUP BY CIUDADFIN)
        WHERE PATHS > 3;
        IF rowcount > 0 THEN
            RAISE_APPLICATION_ERROR(-20002,'No pueden existir mas de 3 caminos de una ciudad a otra');
        END IF;
    END LOOP;
END;
