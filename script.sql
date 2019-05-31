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
