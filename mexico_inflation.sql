DROP DATABASE IF EXISTS mexico_inflation;

CREATE DATABASE mexico_inflation
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE mexico_inflation;

-- Time dimension populated from Banxico API dates
CREATE TABLE period (
    period_id   INT PRIMARY KEY AUTO_INCREMENT,
    period_date DATE        NOT NULL,
    year        INT         NOT NULL,
    month       INT         NOT NULL,
    quarter     INT         NOT NULL,
    label       VARCHAR(10) NOT NULL,
    UNIQUE KEY uq_period_date (period_date),
    UNIQUE KEY uq_period_label (label)
);

CREATE INDEX idx_period_year ON period (year);

-- Economic series catalog from configuration
CREATE TABLE banxico_series (
    series_id   VARCHAR(20)  PRIMARY KEY,
    name        VARCHAR(200) NOT NULL,
    unit        VARCHAR(50)  NOT NULL,
    frequency   VARCHAR(20)  NOT NULL,
    category    VARCHAR(50)  NOT NULL
);

CREATE INDEX idx_series_category ON banxico_series (category);

-- Central fact table storing monthly values
CREATE TABLE observation (
    observation_id INT PRIMARY KEY AUTO_INCREMENT,
    period_id      INT           NOT NULL,
    series_id      VARCHAR(20)   NOT NULL,
    value          DECIMAL(18,6) NOT NULL,
    loaded_at      TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_obs_period FOREIGN KEY (period_id) REFERENCES period(period_id),
    CONSTRAINT fk_obs_series FOREIGN KEY (series_id) REFERENCES banxico_series(series_id),
    UNIQUE KEY uq_observation (period_id, series_id)
);

CREATE INDEX idx_obs_series ON observation (series_id);
CREATE INDEX idx_obs_period ON observation (period_id);

-- Passive audit log for row-level operations
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

-- Batch-level audit tracking for Python API ingestion
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

-- View 1: Accumulated inflation since 2018
CREATE OR REPLACE VIEW vw_termometro_inflacion AS
SELECT
    p.label                            AS period,
    p.year                             AS year,
    ROUND(o.value, 2)                  AS cpi_index,
    ROUND(o.value - 100, 2)            AS accumulated_inflation_since_2018_pct,
    CASE
        WHEN (o.value - 100) <= 15 THEN 'Under Control'
        WHEN (o.value - 100) <= 30 THEN 'Moderate Alert'
        ELSE 'Red Alert: High Prices'
    END                                AS price_status
FROM observation o
JOIN period p ON p.period_id = o.period_id
WHERE o.series_id = 'SP1'
ORDER BY p.period_date;

-- View 2: Purchasing power of 10 MXN relative to UDI
CREATE OR REPLACE VIEW vw_poder_adquisitivo_udis AS
SELECT
    p.label                            AS period,
    p.year                             AS year,
    ROUND(o.value, 6)                  AS udi_value,
    ROUND(10 / o.value, 4)             AS purchasing_power_10_pesos_coin
FROM observation o
JOIN period p ON p.period_id = o.period_id
WHERE o.series_id = 'SP68257'
ORDER BY p.period_date;

-- View 3: CETES 28d vs CPI investment advice
CREATE OR REPLACE VIEW vw_consejo_financiero AS
SELECT
    p.label                            AS period,
    p.year                             AS year,
    ROUND(cetes.value, 4)              AS cetes_rate_28d_pct,
    ROUND(inpc.value, 2)               AS cpi_index,
    CASE
        WHEN cetes.value > 5.0 THEN 'Good time to invest'
        ELSE 'The bank pays very little, look for other options'
    END                                AS advice
FROM observation cetes
JOIN observation inpc
    ON inpc.period_id = cetes.period_id
   AND inpc.series_id = 'SP1'
JOIN period p ON p.period_id = cetes.period_id
WHERE cetes.series_id = 'SF433936'
ORDER BY p.period_date;

-- View 4: MXN purchasing power in US cents
CREATE OR REPLACE VIEW vw_peso_frente_al_dolar AS
SELECT
    p.label                            AS period,
    p.year                             AS year,
    ROUND(o.value, 4)                  AS pesos_per_dollar,
    ROUND((1 / o.value) * 100, 2)      AS us_cents_per_one_peso
FROM observation o
JOIN period p ON p.period_id = o.period_id
WHERE o.series_id = 'SF43718'
ORDER BY p.period_date;

-- View 5: Historical CPI average by month
CREATE OR REPLACE VIEW vw_mes_mas_caro AS
SELECT
    p.month                            AS month_number,
    CASE p.month
        WHEN 1  THEN 'January'
        WHEN 2  THEN 'February'
        WHEN 3  THEN 'March'
        WHEN 4  THEN 'April'
        WHEN 5  THEN 'May'
        WHEN 6  THEN 'June'
        WHEN 7  THEN 'July'
        WHEN 8  THEN 'August'
        WHEN 9  THEN 'September'
        WHEN 10 THEN 'October'
        WHEN 11 THEN 'November'
        WHEN 12 THEN 'December'
    END                                AS month_name,
    ROUND(AVG(o.value), 4)             AS historical_cpi_average,
    COUNT(*)                           AS years_averaged
FROM observation o
JOIN period p ON p.period_id = o.period_id
WHERE o.series_id = 'SP1'
GROUP BY p.month
ORDER BY historical_cpi_average DESC;

-- View 6: Headline vs Core CPI comparison
CREATE OR REPLACE VIEW vw_alerta_volatilidad AS
SELECT
    p.label                                AS period,
    p.year                                 AS year,
    ROUND(gen.value, 2)                    AS headline_cpi,
    ROUND(sub.value, 2)                    AS core_cpi,
    ROUND(gen.value - sub.value, 2)        AS difference_headline_minus_core,
    CASE
        WHEN gen.value > sub.value THEN 'Driven by gasoline or fresh foods'
        WHEN sub.value > gen.value THEN 'Generalized structural inflation'
        ELSE 'Balance between both components'
    END                                    AS inflation_origin
FROM observation gen
JOIN observation sub
    ON sub.period_id = gen.period_id
   AND sub.series_id = 'SP74665'
JOIN period p ON p.period_id = gen.period_id
WHERE gen.series_id = 'SP1'
ORDER BY p.period_date;

DELIMITER $$

-- Inserts or updates an observation validating keys
DROP PROCEDURE IF EXISTS sp_upsert_observation $$
CREATE PROCEDURE sp_upsert_observation(
    IN p_period_id INT,
    IN p_series_id VARCHAR(20),
    IN p_value     DECIMAL(18,6)
)
BEGIN
    IF p_value IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Observation value cannot be NULL';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM period WHERE period_id = p_period_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'The specified period does not exist';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM banxico_series WHERE series_id = p_series_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'The specified series does not exist';
    END IF;

    INSERT INTO observation (period_id, series_id, value)
    VALUES (p_period_id, p_series_id, p_value)
    ON DUPLICATE KEY UPDATE value = VALUES(value), loaded_at = CURRENT_TIMESTAMP;
END $$

-- Returns period_id by normalizing date to first day of month
DROP PROCEDURE IF EXISTS sp_get_period_id_by_date $$
CREATE PROCEDURE sp_get_period_id_by_date(IN p_date DATE)
BEGIN
    DECLARE v_first_day DATE;
    SET v_first_day = DATE_FORMAT(p_date, '%Y-%m-01');
    SELECT period_id FROM period WHERE period_date = v_first_day LIMIT 1;
END $$

-- Logs the start of an API bulk load
DROP PROCEDURE IF EXISTS sp_start_api_load $$
CREATE PROCEDURE sp_start_api_load(
    IN  p_series_id  VARCHAR(20),
    IN  p_start_date DATE,
    IN  p_end_date   DATE,
    OUT p_load_id    INT
)
BEGIN
    INSERT INTO api_load_audit (series_id, start_date, end_date, status)
    VALUES (p_series_id, p_start_date, p_end_date, 'RUNNING');
    SET p_load_id = LAST_INSERT_ID();
END $$

-- Updates metrics and closes load log
DROP PROCEDURE IF EXISTS sp_finish_api_load $$
CREATE PROCEDURE sp_finish_api_load(
    IN p_load_id          INT,
    IN p_records_received INT,
    IN p_records_inserted INT,
    IN p_records_failed   INT,
    IN p_status           VARCHAR(20),
    IN p_error_message    TEXT
)
BEGIN
    UPDATE api_load_audit
    SET records_received = p_records_received,
        records_inserted = p_records_inserted,
        records_failed   = p_records_failed,
        status           = p_status,
        error_message    = p_error_message,
        finished_at      = CURRENT_TIMESTAMP
    WHERE load_id = p_load_id;
END $$

-- Stored procedures mapping views to MongoDB endpoints
DROP PROCEDURE IF EXISTS sp_get_termometro_inflacion $$
CREATE PROCEDURE sp_get_termometro_inflacion() BEGIN SELECT * FROM vw_termometro_inflacion; END $$

DROP PROCEDURE IF EXISTS sp_get_poder_adquisitivo_udis $$
CREATE PROCEDURE sp_get_poder_adquisitivo_udis() BEGIN SELECT * FROM vw_poder_adquisitivo_udis; END $$

DROP PROCEDURE IF EXISTS sp_get_consejo_financiero $$
CREATE PROCEDURE sp_get_consejo_financiero() BEGIN SELECT * FROM vw_consejo_financiero; END $$

DROP PROCEDURE IF EXISTS sp_get_peso_frente_al_dolar $$
CREATE PROCEDURE sp_get_peso_frente_al_dolar() BEGIN SELECT * FROM vw_peso_frente_al_dolar; END $$

DROP PROCEDURE IF EXISTS sp_get_mes_mas_caro $$
CREATE PROCEDURE sp_get_mes_mas_caro() BEGIN SELECT * FROM vw_mes_mas_caro; END $$

DROP PROCEDURE IF EXISTS sp_get_alerta_volatilidad $$
CREATE PROCEDURE sp_get_alerta_volatilidad() BEGIN SELECT * FROM vw_alerta_volatilidad; END $$

-- Logs insert events into audit_log
DROP TRIGGER IF EXISTS trg_observation_after_insert $$
CREATE TRIGGER trg_observation_after_insert AFTER INSERT ON observation FOR EACH ROW
BEGIN
    INSERT INTO audit_log (table_name, operation_type, record_pk, description)
    VALUES ('observation', 'INSERT', NEW.observation_id, CONCAT('New observation. series=', NEW.series_id, ', period=', NEW.period_id, ', value=', NEW.value));
END $$

-- Logs update events if value changed
DROP TRIGGER IF EXISTS trg_observation_after_update $$
CREATE TRIGGER trg_observation_after_update AFTER UPDATE ON observation FOR EACH ROW
BEGIN
    IF OLD.value <> NEW.value THEN
        INSERT INTO audit_log (table_name, operation_type, record_pk, description)
        VALUES ('observation', 'UPDATE', NEW.observation_id, CONCAT('Value updated. series=', NEW.series_id, ', period=', NEW.period_id, ', old=', OLD.value, ', new=', NEW.value));
    END IF;
END $$

-- Logs deletion events into audit_log
DROP TRIGGER IF EXISTS trg_observation_after_delete $$
CREATE TRIGGER trg_observation_after_delete AFTER DELETE ON observation FOR EACH ROW
BEGIN
    INSERT INTO audit_log (table_name, operation_type, record_pk, description)
    VALUES ('observation', 'DELETE', OLD.observation_id, CONCAT('Observation deleted. series=', OLD.series_id, ', period=', OLD.period_id, ', value=', OLD.value));
END $$

DELIMITER ;