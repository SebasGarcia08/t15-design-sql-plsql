SET SERVEROUTPUT ON;

DROP TABLE parametros_sistema CASCADE CONSTRAINTS;

DROP TABLE asignaciones CASCADE CONSTRAINTS;

DROP TABLE solicitudes_creacion_modif CASCADE CONSTRAINTS;

DROP TABLE solicitudes_soporte CASCADE CONSTRAINTS;

DROP TABLE solicitudes CASCADE CONSTRAINTS;

DROP TABLE productos CASCADE CONSTRAINTS;

DROP TABLE funcionarios CASCADE CONSTRAINTS;

DROP TABLE clientes CASCADE CONSTRAINTS;

DROP TABLE tipo_estado_solicitudes CASCADE CONSTRAINTS;

DROP TABLE tipo_soportes CASCADE CONSTRAINTS;

DROP TABLE tipo_productos CASCADE CONSTRAINTS;

-- Tabla de Tipos de Producto
create table tipo_productos (
    id NUMBER PRIMARY KEY,
    nombre VARCHAR2(100)
);

-- Tabla de Tipos de soporte
create table tipo_soportes (
    id NUMBER PRIMARY KEY,
    nombre VARCHAR2(100)
);

-- Tabla de estado de solicitud
create table tipo_estado_solicitudes (
    id NUMBER PRIMARY KEY,
    nombre VARCHAR2(50)
);

-- Tabla de Clientes
create table clientes (
    cedula NUMBER PRIMARY KEY,
    nombre VARCHAR2(100)
);

-- Tabla de funcionarios
create table funcionarios (
    cedula NUMBER PRIMARY KEY,
    nombre VARCHAR2(100)
);

-- Tabla de Productos
create table productos (
    producto_id NUMBER PRIMARY KEY,
    tipo_producto_id NUMBER REFERENCES tipo_productos(id),
    nombre VARCHAR2(100),
    descripcion VARCHAR2(200)
);

-- Tabla base de solicitudes
create table solicitudes (
    id NUMBER PRIMARY KEY,
    cedula NUMBER REFERENCES clientes(cedula),
    observacion VARCHAR2(200),
    fecha_registro DATE
);

-- Tabla de solicitudes de soporte
create table solicitudes_soporte (
    solicitud_id NUMBER REFERENCES solicitudes(id),
    tipo_soporte_id NUMBER REFERENCES tipo_soportes(id),
    producto_id NUMBER REFERENCES productos(producto_id),
    PRIMARY KEY (solicitud_id)
);

-- Tabla de solicitudes de soporte de creación o modificación
create table solicitudes_creacion_modif(
    solicitud_id NUMBER REFERENCES solicitudes(id),
    tipo_producto_id NUMBER REFERENCES tipo_productos(id),
    PRIMARY KEY (solicitud_id)
);

-- Tabla de solicitudes de asignaciones
create table asignaciones (
    solicitud_id NUMBER REFERENCES solicitudes(id),
    funcionario_id NUMBER default null REFERENCES funcionarios(cedula),
    estado_id NUMBER REFERENCES tipo_estado_solicitudes(id),
    fecha_asignacion DATE default null
);

-- Tabla de parámetros del Sistema
create table parametros_sistema (
    parametro_id NUMBER PRIMARY KEY,
    nombre VARCHAR2(100),
    valor VARCHAR2(100)
);


/* Para evitar este error 
Error report:
ORA-00603: ORACLE server session terminated by fatal error
ORA-00600: internal error code, arguments: [kqlidchg0], [], [], [], [], [], [], [], [], [], [], []
ORA-00604: error occurred at recursive SQL level 1
ORA-00001: unique constraint (SYS.I_PLSCOPE_SIG_IDENTIFIER$) violated
00603. 00000 -  "ORACLE server session terminated by fatal error"
*Cause:    An ORACLE server session is in an unrecoverable state.
*Action:   Login to ORACLE again so a new server session will be created
*/
ALTER SESSION SET PLSCOPE_SETTINGS = 'IDENTIFIERS:NONE';

CREATE OR REPLACE PROCEDURE obtener_funcionario_disponible(
    funcionario_asignado OUT NUMBER
) AS
    numero_maximo_asignaciones NUMBER;
    total_asignaciones_funcionario NUMBER;
    num_total_asignaciones NUMBER;
    num_total_funcionarios NUMBER;
BEGIN
    -- Obtener el número máximo de asignaciones de la tabla de parametros_sistema
    SELECT valor INTO numero_maximo_asignaciones
    FROM parametros_sistema
    WHERE parametro_id = 1;
    DBMS_OUTPUT.PUT_LINE('numero_maximo_asignaciones ' || numero_maximo_asignaciones);

    -- Lógica para asignar funcionario
    SELECT COUNT(*) INTO num_total_asignaciones
    FROM asignaciones
    WHERE estado_id = 2;
    DBMS_OUTPUT.PUT_LINE('num_total_asignaciones ' || num_total_asignaciones);
    
    SELECT COUNT(*) INTO num_total_funcionarios
    FROM funcionarios;
    DBMS_OUTPUT.PUT_LINE('num_total_funcionarios ' || num_total_funcionarios);
    
    IF num_total_funcionarios <= 0 THEN
        DBMS_OUTPUT.PUT_LINE('No hay funcionarios! ');
        RAISE NO_DATA_FOUND;
    END IF;

    -- Si hay funcionarios sin solicitudes, asignarlas
    IF num_total_funcionarios > num_total_asignaciones THEN
        SELECT f.cedula INTO funcionario_asignado
        FROM funcionarios f
        WHERE f.cedula NOT IN (
            SELECT a.funcionario_id
            FROM asignaciones a
            WHERE a.estado_id = 2
        )
        AND ROWNUM = 1;

        total_asignaciones_funcionario := 0;
        DBMS_OUTPUT.PUT_LINE('Hay funcionarios libres');

    -- Si todavía hay funcionarios con menos asignaciones que el máximo permitido
    ELSIF FLOOR(num_total_asignaciones / num_total_funcionarios) < numero_maximo_asignaciones THEN
        SELECT cedula, total_asignaciones
        INTO funcionario_asignado, total_asignaciones_funcionario
        FROM (
            SELECT f.cedula, NVL(COUNT(a.solicitud_id), 0) AS total_asignaciones
            FROM funcionarios f
            LEFT JOIN asignaciones a ON f.cedula = a.funcionario_id
            WHERE a.estado_id = 2
            GROUP BY f.cedula
            HAVING COUNT(a.solicitud_id) < numero_maximo_asignaciones -- Funcionarios con menos asignaciones que el número máximo
            ORDER BY total_asignaciones ASC
        )
        WHERE ROWNUM = 1;
    END IF;

    DBMS_OUTPUT.PUT_LINE(
        'Funcionario con menos ocupaciones es ' || funcionario_asignado || ' con ' || total_asignaciones_funcionario || ' ocupaciones.'
    );
END;
/

create or replace procedure asignar_funcionario(
    solicitud_id in number,
    funcionario_asignado number
) as 
    solicitud_pendiente number;
begin
    if funcionario_asignado is not null then
        -- Verificar si la solicitud se encontraba pendiente
        select COUNT(*) into solicitud_pendiente
        from asignaciones a
        where a.solicitud_id = solicitud_id
            and a.estado_id = 1;

        if solicitud_pendiente > 0 then
            -- Si la solicitud se encontraba pendiente, actualizarla
            update asignaciones a
            set 
                funcionario_id = funcionario_asignado,
                estado_id = 2,
                fecha_asignacion = SYSDATE
            where a.solicitud_id = solicitud_id; 
            DBMS_OUTPUT.PUT_LINE(
                'Solicitud estaba pendiente, funcionario asignado: ' || funcionario_asignado
            );
        else
            -- Si la solicitud es nueva
            insert into asignaciones (
                solicitud_id,
                funcionario_id,
                estado_id,
                fecha_asignacion
            )
            values (
                solicitud_id,
                funcionario_asignado,
                2,
                SYSDATE
            );
            DBMS_OUTPUT.PUT_LINE(
                'Solicitud nueva, funcionario asignado: ' || funcionario_asignado
            );
        end if;
    else
        -- Si no hay funcionarios disponibles, dejar pendiente
        insert into asignaciones (
            solicitud_id,
            funcionario_id,
            estado_id,
            fecha_asignacion
        )
        values (
            solicitud_id,
            null,
            1,
            null
        );
        DBMS_OUTPUT.PUT_LINE('No se pudo asignar un funcionario, se deja asginación pendiente');
    end if;
end;
/


CREATE OR REPLACE TRIGGER asignacion_automatica_trig
AFTER INSERT ON solicitudes
FOR EACH ROW
    declare funcionario_asignado number;
BEGIN
    -- Llamada al procedimiento asignar_funcionario pasando el ID de la nueva solicitud
    obtener_funcionario_disponible(funcionario_asignado);
    asignar_funcionario(:NEW.id, funcionario_asignado);
END;
/

-- Procedimiento para la asignación masiva
CREATE OR REPLACE PROCEDURE asignacion_masiva_funcionarios AS
    max_tiempo_pendiente NUMBER;
    funcionario_asignado NUMBER;
BEGIN
    -- Obtener el tiempo máximo en minutos para asignación masiva de la tabla de parametros_sistema
    SELECT valor INTO max_tiempo_pendiente
    FROM parametros_sistema
    WHERE parametro_id = 2;

    -- Cursor para obtener las solicitudes pendientes que han estado pendientes por más tiempo del valor parametrizado
    FOR solicitud IN (
        SELECT a.solicitud_id, s.fecha_registro
        FROM asignaciones a
        INNER JOIN solicitudes s ON a.solicitud_id = s.id
        WHERE a.estado_id = 1
        ORDER BY s.fecha_registro ASC
    ) LOOP
        
        -- Obtener el funcionario disponible
        obtener_funcionario_disponible(funcionario_asignado);
        asignar_funcionario(solicitud.solicitud_id, funcionario_asignado);

        DBMS_OUTPUT.PUT_LINE(
            'Solicitud asignada masivamente a funcionario: ' || funcionario_asignado
        );
        -- Asignar el funcionario a la solicitud pendiente
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('Asignación masiva de funcionarios completada.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error durante la asignación masiva de funcionarios: ' || SQLERRM);
END;
/


BEGIN
    DBMS_SCHEDULER.DROP_JOB('ASIGNACION_MASIVA_JOB');
END;
/


BEGIN
    DBMS_SCHEDULER.CREATE_JOB (
        job_name        => 'ASIGNACION_MASIVA_JOB',
        job_type        => 'PLSQL_BLOCK',
        job_action      => 'BEGIN asignacion_masiva_funcionarios(); END;',
        start_date      => SYSTIMESTAMP,
        repeat_interval => 'FREQ=MINUTELY; INTERVAL=1',
        enabled         => TRUE,
        comments        => 'Job para asignación masiva de funcionarios a solicitudes pendientes'
    );
END;
/