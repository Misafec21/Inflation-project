DROP DATABASE IF EXISTS mexico_inflation;

CREATE DATABASE mexico_inflation
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE mexico_inflation;

-- PHASE 1: DIMENSIONS (Catalogs)

-- table: period - Time dimension. Populated automatically from Banxico API dates.
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


-- table: banxico_series - Economic series catalog populated from the configuration dictionary.
CREATE TABLE banxico_series (
    series_id   VARCHAR(20)  PRIMARY KEY,
    name        VARCHAR(200) NOT NULL,
    unit        VARCHAR(50)  NOT NULL,
    frequency   VARCHAR(20)  NOT NULL,
    category    VARCHAR(50)  NOT NULL
);

CREATE INDEX idx_series_category ON banxico_series (category);


-- PHASE 2: UNIFIED FACT TABLE

-- table: observation - Central fact table storing monthly values for each series. Unique constraint allows safe upserts.
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