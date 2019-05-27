--1.a

CREATE OR REPLACE TRIGGER control_peso_producto
BEFORE INSERT ON PRODUCTO
FOR EACH ROW
DECLARE
    pesomax CAMION.PESOMAX%TYPE;
BEGIN
    SELECT MAX(pesomax) INTO pesomax FROM CAMION;
    IF(:NEW.peso > pesomax) THEN
        RAISE_APPLICATION_ERROR(-1313,'El peso de un producto no puede ser mayor al camion mas grande');
    END IF;
END;

CREATE OR REPLACE TRIGGER control_update_peso_producto
BEFORE UPDATE OF peso ON PRODUCTO
FOR EACH ROW
DECLARE
    pesomax CAMION.PESOMAX%TYPE;
BEGIN
    SELECT MAX(pesomax) INTO pesomax FROM CAMION;
    IF(:NEW.peso > pesomax) THEN
        RAISE_APPLICATION_ERROR(-1313,'El peso de un producto no puede ser mayor al camion mas grande');
    END IF;
END;


--1.b
