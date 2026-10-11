/* ============================================================
    MODELAMIENTO DE BASES DE DATOS
    Semana 9: Evaluación Final Transversal
    Caso: ANFP - Asociación Nacional de Fútbol Profesional
    Conexión: PRY2204_S9
    Estudiante: Camila Sepúlveda Marcos
   ============================================================ */

-- ============================================================
-- SECCIÓN 1: LIMPIEZA
-- Las tablas se eliminan en orden inverso de dependencia
-- (hijas primero, padres al final) para evitar errores de FK.
-- CASCADE CONSTRAINTS elimina las restricciones asociadas.
-- PURGE elimina definitivamente sin usar papelera de reciclaje.
-- En la primera ejecución los DROPs mostrarán
-- "table or view does not exist", esto es esperado.
-- ============================================================

DROP TABLE nivel_idioma         CASCADE CONSTRAINTS PURGE;
DROP TABLE contrato_jugador     CASCADE CONSTRAINTS PURGE;
DROP TABLE jugador_futbol       CASCADE CONSTRAINTS PURGE;
DROP TABLE personal_planta      CASCADE CONSTRAINTS PURGE;
DROP TABLE trabajador           CASCADE CONSTRAINTS PURGE;
DROP TABLE comuna               CASCADE CONSTRAINTS PURGE;
DROP TABLE region               CASCADE CONSTRAINTS PURGE;
DROP TABLE club_futbol          CASCADE CONSTRAINTS PURGE;
DROP TABLE asociacion           CASCADE CONSTRAINTS PURGE;
DROP TABLE escuela_futbol       CASCADE CONSTRAINTS PURGE;
DROP TABLE idioma               CASCADE CONSTRAINTS PURGE;
DROP TABLE estado_civil         CASCADE CONSTRAINTS PURGE;
DROP TABLE genero               CASCADE CONSTRAINTS PURGE;
DROP TABLE nacionalidad         CASCADE CONSTRAINTS PURGE;

-- La secuencia debe eliminarse antes de recrearla.
DROP SEQUENCE sq_club_futbol;

-- ============================================================
-- SECCIÓN 2: SECUENCIA
-- Genera valores automáticos para id_club.
-- Se invoca con sq_club_futbol.NEXTVAL en cada INSERT.
-- ============================================================

CREATE SEQUENCE sq_club_futbol
START WITH 703
INCREMENT BY 4;

-- ============================================================
-- SECCIÓN 3: CREACIÓN DE TABLAS
-- Se crean primero las tablas padre (sin FK) y luego
-- las tablas hija (con FK), respetando el orden de
-- dependencia para evitar errores de integridad referencial.
-- ============================================================

-- ------------------------------------------------------------
-- Tablas sin FK
-- ------------------------------------------------------------

-- Primer nivel de la jerarquía territorial.
CREATE TABLE region (
    id_region       NUMBER(2)    NOT NULL,
    nombre_region   VARCHAR2(40) NOT NULL,
    CONSTRAINT region_pk PRIMARY KEY (id_region)
);

-- Tabla de dominio para el estado civil del trabajador.
CREATE TABLE estado_civil (
    cod_estado_civil         CHAR(3)      NOT NULL,
    descripcion_estado_civil VARCHAR2(20) NOT NULL,
    CONSTRAINT estado_civil_pk PRIMARY KEY (cod_estado_civil)
);

-- Tabla de dominio para el género del trabajador.
CREATE TABLE genero (
    cod_genero         CHAR(1)      NOT NULL,
    descripcion_genero VARCHAR2(10) NOT NULL,
    CONSTRAINT genero_pk PRIMARY KEY (cod_genero)
);

-- IDENTITY genera id_nacionalidad automáticamente:
-- 210, 212, 214... No se incluye en los INSERT.
CREATE TABLE nacionalidad (
    id_nacionalidad          NUMBER GENERATED ALWAYS AS IDENTITY
                             (START WITH 210 INCREMENT BY 2),
    descripcion_nacionalidad VARCHAR2(20) NOT NULL,
    CONSTRAINT nacionalidad_pk PRIMARY KEY (id_nacionalidad)
);

-- Tabla de dominio para los idiomas que dominan los jugadores.
CREATE TABLE idioma (
    id_idioma     NUMBER(3)    NOT NULL,
    nombre_idioma VARCHAR2(20) NOT NULL,
    CONSTRAINT idioma_pk PRIMARY KEY (id_idioma)
);

-- Las restricciones CHECK de fecha y tipo se agregan
-- en la Sección 4 mediante ALTER TABLE.
CREATE TABLE asociacion (
    id_asociacion     NUMBER(2)    NOT NULL,
    nombre_asociacion VARCHAR2(50) NOT NULL,
    fecha_creacion    DATE         NOT NULL,
    tipo_asociacion   CHAR(1)      NOT NULL,
    CONSTRAINT asociacion_pk PRIMARY KEY (id_asociacion)
);

-- La relación con JUGADOR_FUTBOL es opcional:
-- un jugador puede no provenir de ninguna escuela.
CREATE TABLE escuela_futbol (
    id_escuela        NUMBER(4)    NOT NULL,
    nombre_escuela    VARCHAR2(50) NOT NULL,
    capacidad_escuela NUMBER(5)    NOT NULL,
    fecha_fundacion   DATE         NOT NULL,
    CONSTRAINT escuela_futbol_pk PRIMARY KEY (id_escuela)
);

-- id_club se asigna mediante SEQUENCE (no IDENTITY).
-- La restricción UNIQUE de nombre_club se agrega en Sección 4.
CREATE TABLE club_futbol (
    id_club        NUMBER(6)    NOT NULL,
    nombre_club    VARCHAR2(50) NOT NULL,
    patrimonio     NUMBER(12)   NOT NULL,
    ubicacion_club VARCHAR2(80) NOT NULL,
    tipo_club      VARCHAR2(15) NOT NULL,
    CONSTRAINT club_futbol_pk PRIMARY KEY (id_club)
);

-- ------------------------------------------------------------
-- Tablas con FK
-- ------------------------------------------------------------

-- Segundo nivel de la jerarquía territorial.
-- Depende de REGION mediante FK.
CREATE TABLE comuna (
    id_comuna        NUMBER(3)    NOT NULL,
    nombre_comuna    VARCHAR2(30) NOT NULL,
    REGION_id_region NUMBER(2)    NOT NULL,
    CONSTRAINT comuna_pk        PRIMARY KEY (id_comuna),
    CONSTRAINT comuna_region_fk FOREIGN KEY (REGION_id_region)
        REFERENCES region (id_region)
);

-- Supertipo de la jerarquía de trabajadores.
-- Contiene los atributos comunes a jugadores y personal.
-- segundo_nombre y email son opcionales.
-- tipo_trabajador indica la categoría del trabajador.
-- Las FK hacia tablas de dominio son NOT NULL: todo trabajador
-- debe tener comuna, nacionalidad, género y estado civil.
CREATE TABLE trabajador (
    id_inscripcion                NUMBER(9)    NOT NULL,
    rut                           NUMBER(8)    NOT NULL,
    dv                            CHAR(1)      NOT NULL,
    primer_nombre                 VARCHAR2(25) NOT NULL,
    segundo_nombre                VARCHAR2(25) NULL,
    apellido_paterno              VARCHAR2(30) NOT NULL,
    apellido_materno              VARCHAR2(30) NOT NULL,
    sueldo_base                   NUMBER(10)   NOT NULL,
    tipo_trabajador               CHAR(1)      NOT NULL,
    fecha_nacimiento              DATE         NOT NULL,
    telefono_movil                VARCHAR2(15) NOT NULL,
    direccion                     VARCHAR2(80) NOT NULL,
    email                         VARCHAR2(60) NULL,
    COMUNA_id_comuna              NUMBER(3)    NOT NULL,
    NACIONALIDAD_id_nacionalidad  NUMBER(3)    NOT NULL,
    GENERO_cod_genero             CHAR(1)      NOT NULL,
    ESTADO_CIVIL_cod_estado_civil CHAR(3)      NOT NULL,
    CONSTRAINT trabajador_pk              PRIMARY KEY (id_inscripcion),
    CONSTRAINT trabajador_comuna_fk       FOREIGN KEY (COMUNA_id_comuna)
        REFERENCES comuna (id_comuna),
    CONSTRAINT trabajador_nacionalidad_fk FOREIGN KEY (NACIONALIDAD_id_nacionalidad)
        REFERENCES nacionalidad (id_nacionalidad),
    CONSTRAINT trabajador_genero_fk       FOREIGN KEY (GENERO_cod_genero)
        REFERENCES genero (cod_genero),
    CONSTRAINT trabajador_estado_civil_fk FOREIGN KEY (ESTADO_CIVIL_cod_estado_civil)
        REFERENCES estado_civil (cod_estado_civil)
);

-- Subtipo de TRABAJADOR. Su PK es también FK hacia TRABAJADOR,
-- estableciendo la herencia: no puede existir un jugador sin
-- un trabajador con el mismo id_inscripcion.
-- id_asociacion es NOT NULL: todo jugador debe pertenecer a
-- una asociación. id_escuela y anio_fin_amateur son opcionales.
CREATE TABLE jugador_futbol (
    id_inscripcion            NUMBER(9)    NOT NULL,
    puesto                    VARCHAR2(20) NOT NULL,
    monto_total_premios       NUMBER(15)   NOT NULL,
    anio_fin_amateur          NUMBER(4)    NULL,
    ASOCIACION_id_asociacion  NUMBER(2)    NOT NULL,
    ESCUELA_FUTBOL_id_escuela NUMBER(4)    NULL,
    CONSTRAINT jugador_futbol_pk            PRIMARY KEY (id_inscripcion),
    CONSTRAINT jugador_futbol_trabajador_fk FOREIGN KEY (id_inscripcion)
        REFERENCES trabajador (id_inscripcion),
    CONSTRAINT jugador_futbol_asociacion_fk FOREIGN KEY (ASOCIACION_id_asociacion)
        REFERENCES asociacion (id_asociacion),
    CONSTRAINT jf_escuela_futbol_fk         FOREIGN KEY (ESCUELA_FUTBOL_id_escuela)
        REFERENCES escuela_futbol (id_escuela)
);

-- Subtipo de TRABAJADOR. horas_trabajadas y valor_horas_extras
-- son opcionales porque el caso indica "cuando corresponda".
CREATE TABLE personal_planta (
    id_inscripcion     NUMBER(9)  NOT NULL,
    horas_trabajadas   NUMBER(5)  NULL,
    valor_horas_extras NUMBER(10) NULL,
    CONSTRAINT personal_planta_pk            PRIMARY KEY (id_inscripcion),
    CONSTRAINT personal_planta_trabajador_fk FOREIGN KEY (id_inscripcion)
        REFERENCES trabajador (id_inscripcion)
);

-- Resuelve la relación M:N entre JUGADOR_FUTBOL y CLUB_FUTBOL.
-- La PK incluye fecha_inicio para permitir que un jugador
-- pueda tener contratos con el mismo club en distintos períodos.
-- fecha_fin es NULL porque el contrato puede estar vigente.
CREATE TABLE contrato_jugador (
    JUGADOR_FUTBOL_id_inscripcion NUMBER(9) NOT NULL,
    CLUB_FUTBOL_id_club           NUMBER(6) NOT NULL,
    fecha_inicio                  DATE      NOT NULL,
    fecha_fin                     DATE      NULL,
    CONSTRAINT contrato_jugador_pk  PRIMARY KEY (JUGADOR_FUTBOL_id_inscripcion, CLUB_FUTBOL_id_club, fecha_inicio),
    CONSTRAINT cj_jugador_futbol_fk FOREIGN KEY (JUGADOR_FUTBOL_id_inscripcion)
        REFERENCES jugador_futbol (id_inscripcion),
    CONSTRAINT cj_club_futbol_fk    FOREIGN KEY (CLUB_FUTBOL_id_club)
        REFERENCES club_futbol (id_club)
);

-- Resuelve la relación M:N entre JUGADOR_FUTBOL e IDIOMA.
-- Registra el nivel de dominio de cada idioma por jugador.
CREATE TABLE nivel_idioma (
    JUGADOR_FUTBOL_id_inscripcion NUMBER(9)    NOT NULL,
    IDIOMA_id_idioma              NUMBER(3)    NOT NULL,
    nivel_dominio                 VARCHAR2(20) NOT NULL,
    CONSTRAINT nivel_idioma_pk                PRIMARY KEY (JUGADOR_FUTBOL_id_inscripcion, IDIOMA_id_idioma),
    CONSTRAINT nivel_idioma_jugador_futbol_fk FOREIGN KEY (JUGADOR_FUTBOL_id_inscripcion)
        REFERENCES jugador_futbol (id_inscripcion),
    CONSTRAINT nivel_idioma_idioma_fk         FOREIGN KEY (IDIOMA_id_idioma)
        REFERENCES idioma (id_idioma)
);

-- ============================================================
-- SECCIÓN 4: RESTRICCIONES (ALTER TABLE)
-- Restricciones adicionales que se aplican sobre las tablas
-- ya creadas, para mantener el script organizado.
-- ============================================================

-- El nombre de cada club debe ser único en el sistema.
ALTER TABLE club_futbol
ADD CONSTRAINT un_club_futbol_nombre
UNIQUE (nombre_club);

-- La fecha de creación debe ser igual o posterior al 31-12-1980.
ALTER TABLE asociacion
ADD CONSTRAINT ck_asociacion_fecha
CHECK (fecha_creacion >= DATE '1980-12-31');

-- El tipo solo puede ser 'P' (profesional) o 'A' (amateur).
ALTER TABLE asociacion
ADD CONSTRAINT ck_asociacion_tipo
CHECK (tipo_asociacion IN ('P', 'A'));

-- tipo_trabajador indica la categoría: 'J' jugador, 'P' personal de planta.
ALTER TABLE trabajador
ADD CONSTRAINT ck_trabajador_tipo
CHECK (tipo_trabajador IN ('J', 'P'));

-- ============================================================
-- SECCIÓN 5: POBLAMIENTO
-- Solo se pueblan las 5 tablas indicadas en el enunciado,
-- respetando el orden de dependencia.
-- ============================================================

-- REGION
-- Los registros 8 y 16 se agregan para resolver la inconsistencia
-- detectada en la Figura 2 (Concepción → región 8, Chillán → región 16).
INSERT INTO region VALUES (1,  'ARICA Y PARINACOTA Y TARAPACA');
INSERT INTO region VALUES (2,  'ANTOFAGASTA');
INSERT INTO region VALUES (3,  'ATACAMA Y COQUIMBO');
INSERT INTO region VALUES (5,  'VALPARAISO');
INSERT INTO region VALUES (13, 'METROPOLITANA');
INSERT INTO region VALUES (8,  'BIOBIO');
INSERT INTO region VALUES (16, 'NUBLE');

-- COMUNA
INSERT INTO comuna VALUES (101, 'Santiago',    13);
INSERT INTO comuna VALUES (102, 'Valparaíso',  5);
INSERT INTO comuna VALUES (103, 'Concepción',  8);
INSERT INTO comuna VALUES (104, 'Antofagasta', 2);
INSERT INTO comuna VALUES (105, 'Chillán',     16);

-- ASOCIACION
INSERT INTO asociacion VALUES (25, 'Asociación de Fútbol de Santiago',      DATE '2001-05-15', 'P');
INSERT INTO asociacion VALUES (26, 'Asociación Nacional de Fútbol Amateur',  DATE '1998-03-10', 'A');
INSERT INTO asociacion VALUES (27, 'Asociación de Fútbol de Valparaíso',     DATE '1987-07-21', 'P');
INSERT INTO asociacion VALUES (28, 'Asociación de Fútbol de Concepción',     DATE '1995-11-30', 'A');
INSERT INTO asociacion VALUES (29, 'Asociación de Fútbol de Antofagasta',    DATE '2003-06-25', 'P');
INSERT INTO asociacion VALUES (30, 'Asociación de Fútbol de Temuco',         DATE '2010-01-12', 'A');
INSERT INTO asociacion VALUES (31, 'Asociación de Fútbol de Rancagua',       DATE '1999-09-08', 'P');
INSERT INTO asociacion VALUES (32, 'Asociación de Fútbol de Puerto Montt',   DATE '2005-04-20', 'A');
INSERT INTO asociacion VALUES (33, 'Asociación de Fútbol de La Serena',      DATE '2012-08-14', 'P');
INSERT INTO asociacion VALUES (34, 'Asociación de Fútbol de Chillán',        DATE '2018-12-01', 'A');

-- NACIONALIDAD
-- Al ser IDENTITY (GENERATED ALWAYS), Oracle asigna
-- id_nacionalidad automáticamente: 210, 212, 214, 216, 218.
-- No se puede incluir esa columna en el INSERT.
INSERT INTO nacionalidad (descripcion_nacionalidad) VALUES ('Chilena');
INSERT INTO nacionalidad (descripcion_nacionalidad) VALUES ('Argentina');
INSERT INTO nacionalidad (descripcion_nacionalidad) VALUES ('Peruana');
INSERT INTO nacionalidad (descripcion_nacionalidad) VALUES ('Boliviana');
INSERT INTO nacionalidad (descripcion_nacionalidad) VALUES ('Brasileña');

-- CLUB_FUTBOL
-- NEXTVAL obtiene el siguiente valor de la secuencia.
-- Genera: 703, 707, 711, 715, 719.
INSERT INTO club_futbol VALUES (sq_club_futbol.NEXTVAL, 'Colo-Colo',            500000000, 'Av. Marathon 5300',                'Profesional');
INSERT INTO club_futbol VALUES (sq_club_futbol.NEXTVAL, 'Universidad de Chile',  450000000, 'Av. El Parrón 0931',               'Profesional');
INSERT INTO club_futbol VALUES (sq_club_futbol.NEXTVAL, 'Deportes Antofagasta',  180000000, 'Avenida Angamos 01606',            'Profesional');
INSERT INTO club_futbol VALUES (sq_club_futbol.NEXTVAL, 'Huachipato',            220000000, 'Avenida Desiderio García 909',     'Profesional');
INSERT INTO club_futbol VALUES (sq_club_futbol.NEXTVAL, 'Ñublense',              170000000, 'Avenida Pedro Aguirre Cerda 1003', 'Profesional');

-- COMMIT confirma todas las inserciones de esta sesión.
COMMIT;

-- ============================================================
-- SECCIÓN 6: RECUPERACIÓN DE INFORMACIÓN
-- ============================================================

-- Informe 1: Asociaciones de tipo profesional ('P')
-- creadas después del año 2000, ordenadas por fecha DESC.
-- La columna ASOCIACION se obtiene por concatenación con ||.
SELECT
    'ID:' || id_asociacion || ' * ' || nombre_asociacion AS "ASOCIACION",
    TO_CHAR(fecha_creacion, 'DD-MM-YYYY')                AS "CREADA",
    tipo_asociacion                                       AS "TIPO"
FROM asociacion
WHERE tipo_asociacion = 'P'
AND   EXTRACT(YEAR FROM fecha_creacion) > 2000
ORDER BY fecha_creacion DESC;

-- Informe 2: Clubes cuyo nombre contiene 'a', con patrimonio
-- superior a $200.000.000 y de tipo Profesional.
-- La columna PATRIMONIO EN DOLARES se obtiene dividiendo
-- el patrimonio por el tipo de cambio de $955 por dólar.
-- Ordenado por id_club descendente.
SELECT
    id_club          AS "CLUB",
    nombre_club      AS "NOMBRE CLUB",
    patrimonio       AS "PATRIMONIO EN PESOS",
    patrimonio / 955 AS "PATRIMONIO EN DOLARES"
FROM club_futbol
WHERE LOWER(nombre_club) LIKE '%a%'
AND   patrimonio > 200000000
AND   tipo_club = 'Profesional'
ORDER BY id_club DESC;