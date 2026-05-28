USE mexico_inflation;

DELIMITER $$

-- GROUP 1: OPERATIONAL STORED PROCEDURES (Secure Insertion)

-- sp_upsert_observation: Inserts or updates an observation, preventing duplicates via UNIQUE constraints. Validates that values, period, and series exist.
DROP PROCEDURE IF EXISTS sp_upsert_observation $$
CREATE PROCEDURE sp_upsert_observation(
    IN p_period_id INT,
    IN p_series_id VARCHAR(20),
    IN p_value     DECIMAL(18,6)
)
BEGIN
    IF p_value IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Observation value cannot be NULL';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM period WHERE period_id = p_period_id) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'The specified period does not exist in the period table';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM banxico_series WHERE series_id = p_series_id) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'The specified series does not exist in banxico_series';
    END IF;

    INSERT INTO observation (period_id, series_id, value)
    VALUES (p_period_id, p_series_id, p_value)
    ON DUPLICATE KEY UPDATE
        value     = VALUES(value),
        loaded_at = CURRENT_TIMESTAMP;
END $$


-- sp_get_period_id_by_date: Returns the corresponding period_id by normalizing any YYYY-MM-DD date to the first day of the month.
DROP PROCEDURE IF EXISTS sp_get_period_id_by_date $$
CREATE PROCEDURE sp_get_period_id_by_date(
    IN p_date DATE
)
BEGIN
    DECLARE v_first_day DATE;
    SET v_first_day = DATE_FORMAT(p_date, '%Y-%m-01');

    SELECT period_id
    FROM period
    WHERE period_date = v_first_day
    LIMIT 1;
END $$


-- GROUP 2: LOAD AUDIT STORED PROCEDURES

-- sp_start_api_load: Logs the start of a bulk API load and outputs a load_id to trace execution.
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


-- sp_finish_api_load: Updates and closes a registered load log with final records counts, execution status, and error logs if applicable.
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


-- GROUP 3: CITIZEN ENDPOINT STORED PROCEDURES (1:1 correspondence mapping views to endpoints for MongoDB data dumps)

-- sp_get_termometro_inflacion: Outputs data from vw_termometro_inflacion (price status).
DROP PROCEDURE IF EXISTS sp_get_termometro_inflacion $$
CREATE PROCEDURE sp_get_termometro_inflacion()
BEGIN
    SELECT * FROM vw_termometro_inflacion;
END $$


-- sp_get_poder_adquisitivo_udis: Outputs data from vw_poder_adquisitivo_udis (purchasing power).
DROP PROCEDURE IF EXISTS sp_get_poder_adquisitivo_udis $$
CREATE PROCEDURE sp_get_poder_adquisitivo_udis()
BEGIN
    SELECT * FROM vw_poder_adquisitivo_udis;
END $$


-- sp_get_consejo_financiero: Outputs data from vw_consejo_financiero (CETES investment advice).
DROP PROCEDURE IF EXISTS sp_get_consejo_financiero $$
CREATE PROCEDURE sp_get_consejo_financiero()
BEGIN
    SELECT * FROM vw_consejo_financiero;
END $$


-- sp_get_peso_frente_al_dolar: Outputs data from vw_peso_frente_al_dolar (USD cents per MXN).
DROP PROCEDURE IF EXISTS sp_get_peso_frente_al_dolar $$
CREATE PROCEDURE sp_get_peso_frente_al_dolar()
BEGIN
    SELECT * FROM vw_peso_frente_al_dolar;
END $$


-- sp_get_mes_mas_caro: Outputs data from vw_mes_mas_caro (CPI seasonality trends).
DROP PROCEDURE IF EXISTS sp_get_mes_mas_caro $$
CREATE PROCEDURE sp_get_mes_mas_caro()
BEGIN
    SELECT * FROM vw_mes_mas_caro;
END $$


-- sp_get_alerta_volatilidad: Outputs data from vw_alerta_volatilidad (structural vs headline inflation).
DROP PROCEDURE IF EXISTS sp_get_alerta_volatilidad $$
CREATE PROCEDURE sp_get_alerta_volatilidad()
BEGIN
    SELECT * FROM vw_alerta_volatilidad;
END $$

DELIMITER ;
