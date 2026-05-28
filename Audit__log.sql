USE mexico_inflation;

-- PHASE 3: AUDIT LAYER

-- Eliminamos las tablas si ya existen para evitar el error 1050
DROP TABLE IF EXISTS audit_log;
CREATE TABLE audit_log (
    audit_id       INT PRIMARY KEY AUTO_INCREMENT,
    table_name     VARCHAR(50)  NOT NULL,
    operation_type VARCHAR(10)  NOT NULL,
    record_pk      VARCHAR(50)  NOT NULL,
    description    VARCHAR(255),
    user_name      VARCHAR(50)  NOT NULL DEFAULT 'system',
    event_time     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_audit_table ON audit_log (table_name);
CREATE INDEX idx_audit_time  ON audit_log (event_time);


DROP TABLE IF EXISTS api_load_audit;
CREATE TABLE api_load_audit (
    load_id          INT PRIMARY KEY AUTO_INCREMENT,
    series_id        VARCHAR(20) NOT NULL,
    start_date       DATE        NOT NULL,
    end_date         DATE        NOT NULL,
    records_received INT         NOT NULL DEFAULT 0,
    records_inserted INT         NOT NULL DEFAULT 0,
    records_failed   INT         NOT NULL DEFAULT 0,
    status           VARCHAR(20) NOT NULL,
    error_message    TEXT,
    started_at       TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    finished_at      TIMESTAMP   NULL
);

CREATE INDEX idx_load_series ON api_load_audit (series_id);
CREATE INDEX idx_load_status ON api_load_audit (status);