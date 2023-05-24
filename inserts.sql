SET SERVEROUTPUT ON;

-- Inserts para tabla parametros_sistema
INSERT INTO parametros_sistema VALUES (1, 'MAX_SOLICITUDES_FUNCIONARIO', '2');
INSERT INTO parametros_sistema VALUES (2, 'TIEMPO_ASIGNACION_MASIVA_MINUTOS', '1');


-- Inserts para tabla tipo_productos
INSERT INTO tipo_productos VALUES (1, 'Consultoría SAP');
INSERT INTO tipo_productos VALUES (2, 'Desarrollo de e-commerce');
INSERT INTO tipo_productos VALUES (3, 'Consultoría en analítica de datos');

-- Inserts para tabla tipo_soportes
INSERT INTO tipo_soportes VALUES (1, 'Infraestructura');
INSERT INTO tipo_soportes VALUES (2, 'Bugs en el sistema');
INSERT INTO tipo_soportes VALUES (3, 'Facturación');

-- Inserts para tabla tipo_estado_solicitudes
INSERT INTO tipo_estado_solicitudes VALUES (1, 'Pendiente');
INSERT INTO tipo_estado_solicitudes VALUES (2, 'Asignada');
INSERT INTO tipo_estado_solicitudes VALUES (3, 'Finalizada');

-- Inserts para tabla clientes
INSERT INTO clientes VALUES (1, 'Arabelo');
INSERT INTO clientes VALUES (2, 'Bourbon');
INSERT INTO clientes VALUES (3, 'Carlos');
INSERT INTO clientes VALUES (4, 'Dorian');
INSERT INTO clientes VALUES (5, 'Erling');

-- Inserts para tabla funcionarios
INSERT INTO funcionarios VALUES (1, 'Ariel');
INSERT INTO funcionarios VALUES (2, 'Bernardo');

-- Inserts para tabla productos
INSERT INTO productos VALUES (1, 1, 'Consultoría SAP 1', 'A');
INSERT INTO productos VALUES (2, 2, 'E-commerce A', 'B');
INSERT INTO productos VALUES (3, 3, 'Consultoría kaggle', 'C');


-- Inserts para tabla solicitudes
INSERT INTO solicitudes VALUES (1, 1, 'Solicitud arabelo', SYSDATE);
INSERT INTO solicitudes_creacion_modif VALUES (1, 1);

INSERT INTO solicitudes VALUES (2, 2, 'E-commerce solicitud Bourbon', SYSDATE);
INSERT INTO solicitudes_creacion_modif VALUES (2, 2);

-- Cada uno de los 2 funcionarios debería tener asignada 1 solicitud

select * from asignaciones; 

/* 
Ahora se le debe asignar más de una solicitud a cada funcionario, de tal forma que 
quede un funcionario con el máximo número de asignaciones.
*/
INSERT INTO solicitudes VALUES (3, 3, 'consultoria kaggle Carlos', SYSDATE);
INSERT INTO solicitudes_creacion_modif VALUES (3, 3);

INSERT INTO solicitudes VALUES (4, 4, 'consultoria kaggle Dorian', SYSDATE);
INSERT INTO solicitudes_creacion_modif VALUES (4, 1);

select * from asignaciones; 

-- Ahora con una nueva solicitud, esta debería quedar pendiente (con estado 1)
INSERT INTO solicitudes VALUES (5, 5, 'consultoria kaggle Erling', SYSDATE);
INSERT INTO solicitudes_creacion_modif VALUES (5, 1);

select * from asignaciones; 

-- Ahora, supongamos que ya se completó la primera solicitud, y por tanto, el 
-- funcionario 1 puede tomar otra solicitud
update asignaciones 
    set estado_id = 3
where solicitud_id = 1;

select * from asignaciones; 

-- Probar asignación masiva, solo actualizará la solicitud 5,
-- aisgnándola al funcionario que esté libre
begin
    DBMS_OUTPUT.PUT_LINE('Probando asignación masiva ');
    asignacion_masiva_funcionarios();
end;

-- Verificar ejecuciones del trigger

SELECT *
FROM all_scheduler_job_run_details
WHERE job_name = 'ASIGNACION_MASIVA_JOB';


COMMIT;

