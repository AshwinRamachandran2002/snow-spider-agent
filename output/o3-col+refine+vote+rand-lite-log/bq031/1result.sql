-- Daily weather (metric units) for Rochester NY, 2019-01-01 – 2019-03-31,
-- plus 8-day moving averages and their lag-1 … lag-8 differences.
WITH rochester_raw AS (
  SELECT
    PARSE_DATE('%Y%m%d', CONCAT(g.year, g.mo, g.da))                                   AS date,
    ROUND((g.temp - 32) * 5/9, 1)                                                      AS temp_c,          -- °C
    ROUND(CASE WHEN g.prcp = 99.99 THEN NULL ELSE g.prcp * 2.54 END, 1)                AS prcp_cm,         -- cm
    ROUND(SAFE_CAST(g.wdsp AS FLOAT64) * 0.514444, 1)                                  AS wind_ms          -- m s⁻¹
  FROM `bigquery-public-data.noaa_gsod.gsod2019`  AS g
  JOIN `bigquery-public-data.noaa_gsod.stations`  AS s
    ON g.stn = s.usaf AND g.wban = s.wban
  WHERE LOWER(TRIM(s.name)) LIKE '%rochester%'     -- Rochester sites
    AND s.state = 'NY'                             -- New York
    AND CONCAT(g.year, g.mo, g.da) BETWEEN '20190101' AND '20190331'
),
-- If more than one Rochester station reports, average them to one value per day.
daily AS (
  SELECT
    date,
    AVG(temp_c)  AS temp_c,
    AVG(prcp_cm) AS prcp_cm,
    AVG(wind_ms) AS wind_ms
  FROM rochester_raw
  GROUP BY date
),
-- 8-day (current + 7 previous days) moving averages.
ma8 AS (
  SELECT
    d.*,
    ROUND(AVG(temp_c)  OVER w, 1) AS ma8_temp_c,
    ROUND(AVG(prcp_cm) OVER w, 1) AS ma8_prcp_cm,
    ROUND(AVG(wind_ms) OVER w, 1) AS ma8_wind_ms
  FROM daily d
  WINDOW w AS (ORDER BY date ROWS BETWEEN 7 PRECEDING AND CURRENT ROW)
),
-- Differences between today’s MA-8 and the MA-8 from 1-8 days earlier.
final AS (
  SELECT
    date,
    temp_c,
    prcp_cm,
    wind_ms,
    ma8_temp_c,
    ma8_prcp_cm,
    ma8_wind_ms,
    -- temperature lags
    ROUND(ma8_temp_c - LAG(ma8_temp_c, 1) OVER o, 1) AS diff_temp_lag1,
    ROUND(ma8_temp_c - LAG(ma8_temp_c, 2) OVER o, 1) AS diff_temp_lag2,
    ROUND(ma8_temp_c - LAG(ma8_temp_c, 3) OVER o, 1) AS diff_temp_lag3,
    ROUND(ma8_temp_c - LAG(ma8_temp_c, 4) OVER o, 1) AS diff_temp_lag4,
    ROUND(ma8_temp_c - LAG(ma8_temp_c, 5) OVER o, 1) AS diff_temp_lag5,
    ROUND(ma8_temp_c - LAG(ma8_temp_c, 6) OVER o, 1) AS diff_temp_lag6,
    ROUND(ma8_temp_c - LAG(ma8_temp_c, 7) OVER o, 1) AS diff_temp_lag7,
    ROUND(ma8_temp_c - LAG(ma8_temp_c, 8) OVER o, 1) AS diff_temp_lag8,
    -- precipitation lags
    ROUND(ma8_prcp_cm - LAG(ma8_prcp_cm, 1) OVER o, 1) AS diff_prcp_lag1,
    ROUND(ma8_prcp_cm - LAG(ma8_prcp_cm, 2) OVER o, 1) AS diff_prcp_lag2,
    ROUND(ma8_prcp_cm - LAG(ma8_prcp_cm, 3) OVER o, 1) AS diff_prcp_lag3,
    ROUND(ma8_prcp_cm - LAG(ma8_prcp_cm, 4) OVER o, 1) AS diff_prcp_lag4,
    ROUND(ma8_prcp_cm - LAG(ma8_prcp_cm, 5) OVER o, 1) AS diff_prcp_lag5,
    ROUND(ma8_prcp_cm - LAG(ma8_prcp_cm, 6) OVER o, 1) AS diff_prcp_lag6,
    ROUND(ma8_prcp_cm - LAG(ma8_prcp_cm, 7) OVER o, 1) AS diff_prcp_lag7,
    ROUND(ma8_prcp_cm - LAG(ma8_prcp_cm, 8) OVER o, 1) AS diff_prcp_lag8,
    -- wind-speed lags
    ROUND(ma8_wind_ms - LAG(ma8_wind_ms, 1) OVER o, 1) AS diff_wind_lag1,
    ROUND(ma8_wind_ms - LAG(ma8_wind_ms, 2) OVER o, 1) AS diff_wind_lag2,
    ROUND(ma8_wind_ms - LAG(ma8_wind_ms, 3) OVER o, 1) AS diff_wind_lag3,
    ROUND(ma8_wind_ms - LAG(ma8_wind_ms, 4) OVER o, 1) AS diff_wind_lag4,
    ROUND(ma8_wind_ms - LAG(ma8_wind_ms, 5) OVER o, 1) AS diff_wind_lag5,
    ROUND(ma8_wind_ms - LAG(ma8_wind_ms, 6) OVER o, 1) AS diff_wind_lag6,
    ROUND(ma8_wind_ms - LAG(ma8_wind_ms, 7) OVER o, 1) AS diff_wind_lag7,
    ROUND(ma8_wind_ms - LAG(ma8_wind_ms, 8) OVER o, 1) AS diff_wind_lag8
  FROM ma8
  WINDOW o AS (ORDER BY date)
)
SELECT *
FROM final
WHERE date >= '2019-01-09'      -- first day with a complete 8-day window
ORDER BY date;