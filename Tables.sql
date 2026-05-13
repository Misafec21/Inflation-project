

CREATE DATABASE IF NOT EXISTS inflacion_mexico
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE inflacion_mexico;

-- TABLAS PRINCIPALES

-- ─── 1. PERIODO ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS PERIODO (
    id_periodo      INT            NOT NULL AUTO_INCREMENT,
    fecha           DATE           NOT NULL,
    anio            SMALLINT       NOT NULL,
    mes             TINYINT        NULL COMMENT '1-12; NULL si periodicidad anual',
    quincena        TINYINT        NULL COMMENT '1 o 2; NULL si es mensual',
    etiqueta        VARCHAR(20)    NOT NULL COMMENT 'Ej: 2022-01, 2022-01-1Q',
    CONSTRAINT pk_periodo          PRIMARY KEY (id_periodo),
    CONSTRAINT uq_periodo_etiqueta UNIQUE (etiqueta)
) COMMENT='Tabla ancla temporal. Todas las mediciones la referencian.';

-- ─── 2. INPC_GENERAL ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS INPC_GENERAL (
    id_registro         BIGINT         NOT NULL AUTO_INCREMENT,
    id_periodo          INT            NOT NULL,
    valor_indice        DECIMAL(10,4)  NOT NULL COMMENT 'Base 2a. quincena jul 2018=100',
    var_mensual_pct     DECIMAL(7,4)   NULL,
    var_anual_pct       DECIMAL(7,4)   NULL,
    var_quincenal_pct   DECIMAL(7,4)   NULL,
    inflacion_acumulada DECIMAL(10,4)  NULL COMMENT 'Acumulado desde ene-2022',
    serie_banxico       VARCHAR(10)    NOT NULL DEFAULT 'SP1',
    fecha_ingesta       TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_inpc_general      PRIMARY KEY (id_registro),
    CONSTRAINT fk_inpcg_periodo     FOREIGN KEY (id_periodo) REFERENCES PERIODO(id_periodo),
    CONSTRAINT uq_inpcg_periodo     UNIQUE (id_periodo)
) COMMENT='P1 – Trayectoria histórica. INPC general mensual.';

-- ─── 3. COMPONENTE_PRECIO ────────────────────────────────────
CREATE TABLE IF NOT EXISTS COMPONENTE_PRECIO (
    id_componente   INT            NOT NULL AUTO_INCREMENT,
    id_padre        INT            NULL COMMENT 'FK autorreferencial; NULL = raíz',
    clave           VARCHAR(20)    NOT NULL,
    nombre          VARCHAR(120)   NOT NULL,
    clasificacion   VARCHAR(20)    NOT NULL COMMENT 'subyacente | no_subyacente | general',
    ponderador_pct  DECIMAL(7,4)   NOT NULL,
    nivel           TINYINT        NOT NULL COMMENT '1=general 2=sub/no-sub 3=rubro',
    serie_banxico   VARCHAR(10)    NULL,
    CONSTRAINT pk_componente        PRIMARY KEY (id_componente),
    CONSTRAINT uq_componente_clave  UNIQUE (clave),
    CONSTRAINT fk_comp_padre        FOREIGN KEY (id_padre) REFERENCES COMPONENTE_PRECIO(id_componente)
) COMMENT='P4 – Componentes. Jerarquía recursiva del INPC.';

-- ─── 4. INPC_COMPONENTE ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS INPC_COMPONENTE (
    id_detalle      BIGINT         NOT NULL AUTO_INCREMENT,
    id_periodo      INT            NOT NULL,
    id_componente   INT            NOT NULL,
    valor_indice    DECIMAL(10,4)  NOT NULL,
    var_mensual_pct DECIMAL(7,4)   NULL,
    var_anual_pct   DECIMAL(7,4)   NULL,
    incidencia_pp   DECIMAL(7,4)   NULL COMMENT 'Puntos porcentuales al INPC general',
    fecha_ingesta   TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_inpc_componente   PRIMARY KEY (id_detalle),
    CONSTRAINT fk_inpcc_periodo     FOREIGN KEY (id_periodo)    REFERENCES PERIODO(id_periodo),
    CONSTRAINT fk_inpcc_comp        FOREIGN KEY (id_componente) REFERENCES COMPONENTE_PRECIO(id_componente),
    CONSTRAINT uq_inpcc_periodo_comp UNIQUE (id_periodo, id_componente)
) COMMENT='P4 – Componentes. Valores históricos por rubro.';

-- ─── 5. PRODUCTO_CANASTA ─────────────────────────────────────
CREATE TABLE IF NOT EXISTS PRODUCTO_CANASTA (
    id_producto     INT            NOT NULL AUTO_INCREMENT,
    id_componente   INT            NOT NULL,
    nombre          VARCHAR(100)   NOT NULL,
    unidad_medida   VARCHAR(30)    NOT NULL,
    es_basico       BOOLEAN        NOT NULL DEFAULT TRUE,
    incluido_pacic  BOOLEAN        NOT NULL DEFAULT FALSE,
    serie_banxico   VARCHAR(10)    NULL,
    CONSTRAINT pk_producto          PRIMARY KEY (id_producto),
    CONSTRAINT fk_prod_componente   FOREIGN KEY (id_componente) REFERENCES COMPONENTE_PRECIO(id_componente)
) COMMENT='P2 – Canasta básica. Genéricos del INPC.';

-- ─── 6. PRECIO_PRODUCTO ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS PRECIO_PRODUCTO (
    id_precio       BIGINT         NOT NULL AUTO_INCREMENT,
    id_producto     INT            NOT NULL,
    id_periodo      INT            NOT NULL,
    valor_indice    DECIMAL(10,4)  NOT NULL,
    var_mensual_pct DECIMAL(7,4)   NULL,
    var_anual_pct   DECIMAL(7,4)   NULL,
    fecha_ingesta   TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_precio            PRIMARY KEY (id_precio),
    CONSTRAINT fk_precio_prod       FOREIGN KEY (id_producto) REFERENCES PRODUCTO_CANASTA(id_producto),
    CONSTRAINT fk_precio_periodo    FOREIGN KEY (id_periodo)  REFERENCES PERIODO(id_periodo),
    CONSTRAINT uq_precio_prod_per   UNIQUE (id_producto, id_periodo)
) COMMENT='P2 – Canasta básica. Historial de precios por producto.';

-- ─── 7. SALARIO_REFERENCIA ───────────────────────────────────
CREATE TABLE IF NOT EXISTS SALARIO_REFERENCIA (
    id_salario          INT            NOT NULL AUTO_INCREMENT,
    id_periodo          INT            NOT NULL,
    tipo                VARCHAR(30)    NOT NULL COMMENT 'minimo_general | zona_frontera',
    monto_nominal       DECIMAL(10,2)  NOT NULL COMMENT 'Pesos corrientes diarios',
    monto_real          DECIMAL(10,2)  NULL     COMMENT 'Deflactado con INPC (base 2022)',
    var_real_anual_pct  DECIMAL(7,4)   NULL,
    brecha_inflacion    DECIMAL(7,4)   NULL     COMMENT 'Alza nominal - inflacion anual',
    fecha_ingesta       TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_salario           PRIMARY KEY (id_salario),
    CONSTRAINT fk_sal_periodo       FOREIGN KEY (id_periodo) REFERENCES PERIODO(id_periodo),
    CONSTRAINT uq_sal_periodo_tipo  UNIQUE (id_periodo, tipo)
) COMMENT='P3 – Poder adquisitivo. Salarios nominales y reales.';

-- ─── 8. REGION ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS REGION (
    id_region       INT            NOT NULL AUTO_INCREMENT,
    nombre          VARCHAR(50)    NOT NULL,
    zona_geografica VARCHAR(30)    NOT NULL,
    CONSTRAINT pk_region            PRIMARY KEY (id_region),
    CONSTRAINT uq_region_nombre     UNIQUE (nombre)
) COMMENT='P5 – Desigualdad regional. Catálogo de regiones.';

-- ─── 9. CIUDAD ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS CIUDAD (
    id_ciudad           INT            NOT NULL AUTO_INCREMENT,
    id_region           INT            NOT NULL,
    nombre              VARCHAR(80)    NOT NULL,
    estado              VARCHAR(50)    NOT NULL,
    zona_calor_electrico BOOLEAN       NOT NULL DEFAULT FALSE,
    clave_inegi         VARCHAR(10)    NULL,
    CONSTRAINT pk_ciudad            PRIMARY KEY (id_ciudad),
    CONSTRAINT fk_ciudad_region     FOREIGN KEY (id_region) REFERENCES REGION(id_region)
) COMMENT='P5 – Desigualdad regional. 55+ ciudades del INPC.';

-- ─── 10. INPC_CIUDAD ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS INPC_CIUDAD (
    id_inpc_ciudad  BIGINT         NOT NULL AUTO_INCREMENT,
    id_ciudad       INT            NOT NULL,
    id_periodo      INT            NOT NULL,
    valor_indice    DECIMAL(10,4)  NOT NULL,
    var_anual_pct   DECIMAL(7,4)   NULL,
    ranking_nacional SMALLINT      NULL COMMENT '1 = ciudad con mayor inflacion ese período',
    serie_banxico   VARCHAR(10)    NULL,
    fecha_ingesta   TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_inpc_ciudad       PRIMARY KEY (id_inpc_ciudad),
    CONSTRAINT fk_inpccity_ciudad   FOREIGN KEY (id_ciudad)  REFERENCES CIUDAD(id_ciudad),
    CONSTRAINT fk_inpccity_periodo  FOREIGN KEY (id_periodo) REFERENCES PERIODO(id_periodo),
    CONSTRAINT uq_inpccity_cxp      UNIQUE (id_ciudad, id_periodo)
) COMMENT='P5 – Desigualdad regional. INPC histórico por ciudad.';
