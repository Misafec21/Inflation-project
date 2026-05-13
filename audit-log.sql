-- ============================================================
--  BASE DE DATOS: INFLACIÓN EN MÉXICO
--  Commit 2: Tablas de auditoría
-- ============================================================

USE inflacion_mexico;

-- ─── AUDITORIA_LOG ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS AUDITORIA_LOG (
    id_log          BIGINT         NOT NULL AUTO_INCREMENT,
    tabla_afectada  VARCHAR(60)    NOT NULL,
    id_registro     VARCHAR(40)    NOT NULL COMMENT 'PK del registro afectado (como texto)',
    operacion       ENUM('INSERT','UPDATE','DELETE') NOT NULL,
    campo_modificado VARCHAR(60)   NULL     COMMENT 'NULL en INSERT/DELETE completo',
    valor_anterior  TEXT           NULL,
    valor_nuevo     TEXT           NULL,
    usuario_db      VARCHAR(100)   NOT NULL DEFAULT (CURRENT_USER()),
    fecha_cambio    TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    host_origen     VARCHAR(100)   NULL,
    CONSTRAINT pk_auditoria         PRIMARY KEY (id_log)
) COMMENT='Tabla central de auditoría. Registra todos los cambios.';

-- ─── AUDITORIA_CARGA_API ─────────────────────────────────────
CREATE TABLE IF NOT EXISTS AUDITORIA_CARGA_API (
    id_carga        INT            NOT NULL AUTO_INCREMENT,
    series_solicitadas TEXT        NOT NULL COMMENT 'Códigos separados por coma',
    fecha_inicio    TIMESTAMP      NOT NULL,
    fecha_fin       TIMESTAMP      NULL,
    registros_insertados INT       NOT NULL DEFAULT 0,
    registros_actualizados INT     NOT NULL DEFAULT 0,
    estado          ENUM('iniciada','completada','error') NOT NULL DEFAULT 'iniciada',
    detalle_error   TEXT           NULL,
    duracion_seg    DECIMAL(8,2)   NULL,
    usuario_db      VARCHAR(100)   NOT NULL DEFAULT (CURRENT_USER()),
    CONSTRAINT pk_carga_api         PRIMARY KEY (id_carga)
) COMMENT='Auditoría de cada ejecución del script Python que consume el API.';
