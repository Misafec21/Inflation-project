USE mexico_inflation;

-- PHASE 4: AUDIT TRIGGERS

DELIMITER $$

-- trigger: trg_observation_after_insert - Logs new observation inserts into audit_log.
DROP TRIGGER IF EXISTS trg_observation_after_insert $$
CREATE TRIGGER trg_observation_after_insert
AFTER INSERT ON observation
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (table_name, operation_type, record_pk, description)
    VALUES (
        'observation',
        'INSERT',
        NEW.observation_id,
        CONCAT('New observation. series=', NEW.series_id,
               ', period=', NEW.period_id,
               ', value=', NEW.value)
    );
END $$


-- trigger: trg_observation_after_update - Logs value modifications into audit_log only if the numeric value actually changed.
DROP TRIGGER IF EXISTS trg_observation_after_update $$
CREATE TRIGGER trg_observation_after_update
AFTER UPDATE ON observation
FOR EACH ROW
BEGIN
    IF OLD.value <> NEW.value THEN
        INSERT INTO audit_log (table_name, operation_type, record_pk, description)
        VALUES (
            'observation',
            'UPDATE',
            NEW.observation_id,
            CONCAT('Value updated. series=', NEW.series_id,
                   ', period=', NEW.period_id,
                   ', old=', OLD.value, ', new=', NEW.value)
        );
    END IF;
END $$


-- trigger: trg_observation_after_delete - Logs deletion events into audit_log.
DROP TRIGGER IF EXISTS trg_observation_after_delete $$
CREATE TRIGGER trg_observation_after_delete
AFTER DELETE ON observation
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (table_name, operation_type, record_pk, description)
    VALUES (
        'observation',
        'DELETE',
        OLD.observation_id,
        CONCAT('Observation deleted. series=', OLD.series_id,
               ', period=', OLD.period_id,
               ', value=', OLD.value)
    );
END $$

DELIMITER ;