USE mexico_inflation;

-- VIEW 1: vw_termometro_inflacion - Measures accumulated inflation since the 2018 base year (CPI - 100).
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

-- VIEW 2: vw_poder_adquisitivo_udis - Measures the real purchasing power of a 10-peso coin relative to UDI value.
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

-- VIEW 3: vw_consejo_financiero - Compares 28-day CETES rates against CPI to generate investment advice.
CREATE OR REPLACE VIEW vw_consejo_financiero AS
SELECT
    p.label                            AS period,
    p.year                             AS year,
    ROUND(cetes.value, 4)              AS cetes_rate_28d_pct,
    ROUND(inpc.value, 2)               AS cpi_index,
    CASE
        WHEN cetes.value > 5.0 THEN '💰 Good time to invest'
        ELSE '🛒 The bank pays very little, look for other options'
    END                                AS advice
FROM observation cetes
JOIN observation inpc
    ON inpc.period_id = cetes.period_id
   AND inpc.series_id = 'SP1'
JOIN period p ON p.period_id = cetes.period_id
WHERE cetes.series_id = 'SF433936'
ORDER BY p.period_date;

-- VIEW 4: vw_peso_frente_al_dolar - Inverts the exchange rate to show MXN purchasing power in US cents.
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

-- VIEW 5: vw_mes_mas_caro - Averages historical CPI by month to identify seasonal inflation trends.
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

-- VIEW 6: vw_alerta_volatilidad - Compares Headline vs Core CPI to determine the structural origin of inflation.
CREATE OR REPLACE VIEW vw_alerta_volatilidad AS
SELECT
    p.label                                AS period,
    p.year                                 AS year,
    ROUND(gen.value, 2)                    AS headline_cpi,
    ROUND(sub.value, 2)                    AS core_cpi,
    ROUND(gen.value - sub.value, 2)        AS difference_headline_minus_core,
    CASE
        WHEN gen.value > sub.value THEN 'Driven by gasoline or fresh foods'
        WHEN sub.value > gen.value THEN ' Generalized structural inflation'
        ELSE 'Balance between both components'
    END                                    AS inflation_origin
FROM observation gen
JOIN observation sub
    ON sub.period_id = gen.period_id
   AND sub.series_id = 'SP74665'
JOIN period p ON p.period_id = gen.period_id
WHERE gen.series_id = 'SP1'
ORDER BY p.period_date;