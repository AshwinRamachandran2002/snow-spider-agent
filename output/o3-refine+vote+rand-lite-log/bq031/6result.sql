-- Daily weather (mean across all Rochester‑NY stations), 8‑day moving averages
-- and lag‑1 … lag‑8 differences, 2019‑01‑09 – 2019‑03‑31
WITH
/* 1.  Rochester, NY station list */
rochester_stations AS (
  SELECT
    usaf ,
    wban
  FROM `bigquery-public-data.noaa_gsod.stations`
  WHERE UPPER(name)     LIKE '%ROCHESTER%'
    AND state           =  'NY'
),
/* 2.  Raw 2019 GSOD rows for those stations & days of interest */
raw AS (
  SELECT
    PARSE_DATE('%Y%m%d', CONCAT(year, mo, da))              AS obs_date,
    CAST(temp  AS FLOAT64)                                  AS temp_f,
    CAST(prcp  AS FLOAT64)                                  AS prcp_in,
    SAFE_CAST(wdsp AS FLOAT64)                              AS wdsp_kts
  FROM `bigquery-public-data.noaa_gsod.gsod2019` g
  JOIN rochester_stations s
    ON g.stn = s.usaf AND g.wban = s.wban
  WHERE PARSE_DATE('%Y%m%d', CONCAT(year, mo, da))
        BETWEEN '2019-01-01' AND '2019-03-31'
),
/* 3.  One daily value (mean if >1 station) + unit conversion + NA handling */
daily AS (
  SELECT
    obs_date                                             AS dt,
    -- Fahrenheit → °C
    AVG(IF(temp_f  = 9999.9,         NULL,
            (temp_f - 32) * 5/9))                        AS temp_c,
    -- inches → cm
    AVG(IF(prcp_in = 99.99,          NULL,
            prcp_in * 2.54))                             AS prcp_cm,
    -- knots  → m/s
    AVG(IF(wdsp_kts = 999.9,         NULL,
            wdsp_kts * 0.514444))                        AS wind_ms
  FROM raw
  GROUP BY dt
),
/* 4.  8‑day moving averages */
ma AS (
  SELECT
    dt,
    temp_c,
    prcp_cm,
    wind_ms,
    AVG(temp_c)  OVER (ORDER BY dt ROWS BETWEEN 7 PRECEDING AND CURRENT ROW)
        AS temp_ma8,
    AVG(prcp_cm) OVER (ORDER BY dt ROWS BETWEEN 7 PRECEDING AND CURRENT ROW)
        AS prcp_ma8,
    AVG(wind_ms) OVER (ORDER BY dt ROWS BETWEEN 7 PRECEDING AND CURRENT ROW)
        AS wind_ma8
  FROM daily
),
/* 5.  Lag‑difference calculations */
lagged AS (
  SELECT
    dt,
    temp_c, prcp_cm, wind_ms,
    temp_ma8, prcp_ma8, wind_ma8,
    -- temperature lags
    temp_ma8 - LAG(temp_ma8, 1) OVER (ORDER BY dt) AS temp_diff_lag1,
    temp_ma8 - LAG(temp_ma8, 2) OVER (ORDER BY dt) AS temp_diff_lag2,
    temp_ma8 - LAG(temp_ma8, 3) OVER (ORDER BY dt) AS temp_diff_lag3,
    temp_ma8 - LAG(temp_ma8, 4) OVER (ORDER BY dt) AS temp_diff_lag4,
    temp_ma8 - LAG(temp_ma8, 5) OVER (ORDER BY dt) AS temp_diff_lag5,
    temp_ma8 - LAG(temp_ma8, 6) OVER (ORDER BY dt) AS temp_diff_lag6,
    temp_ma8 - LAG(temp_ma8, 7) OVER (ORDER BY dt) AS temp_diff_lag7,
    temp_ma8 - LAG(temp_ma8, 8) OVER (ORDER BY dt) AS temp_diff_lag8,
    -- precipitation lags
    prcp_ma8 - LAG(prcp_ma8, 1) OVER (ORDER BY dt) AS prcp_diff_lag1,
    prcp_ma8 - LAG(prcp_ma8, 2) OVER (ORDER BY dt) AS prcp_diff_lag2,
    prcp_ma8 - LAG(prcp_ma8, 3) OVER (ORDER BY dt) AS prcp_diff_lag3,
    prcp_ma8 - LAG(prcp_ma8, 4) OVER (ORDER BY dt) AS prcp_diff_lag4,
    prcp_ma8 - LAG(prcp_ma8, 5) OVER (ORDER BY dt) AS prcp_diff_lag5,
    prcp_ma8 - LAG(prcp_ma8, 6) OVER (ORDER BY dt) AS prcp_diff_lag6,
    prcp_ma8 - LAG(prcp_ma8, 7) OVER (ORDER BY dt) AS prcp_diff_lag7,
    prcp_ma8 - LAG(prcp_ma8, 8) OVER (ORDER BY dt) AS prcp_diff_lag8,
    -- wind‑speed lags
    wind_ma8 - LAG(wind_ma8, 1) OVER (ORDER BY dt) AS wind_diff_lag1,
    wind_ma8 - LAG(wind_ma8, 2) OVER (ORDER BY dt) AS wind_diff_lag2,
    wind_ma8 - LAG(wind_ma8, 3) OVER (ORDER BY dt) AS wind_diff_lag3,
    wind_ma8 - LAG(wind_ma8, 4) OVER (ORDER BY dt) AS wind_diff_lag4,
    wind_ma8 - LAG(wind_ma8, 5) OVER (ORDER BY dt) AS wind_diff_lag5,
    wind_ma8 - LAG(wind_ma8, 6) OVER (ORDER BY dt) AS wind_diff_lag6,
    wind_ma8 - LAG(wind_ma8, 7) OVER (ORDER BY dt) AS wind_diff_lag7,
    wind_ma8 - LAG(wind_ma8, 8) OVER (ORDER BY dt) AS wind_diff_lag8
  FROM ma
)
/* 6.  Final output: round to 1 decimal, start 2019‑01‑09 */
SELECT
  dt                                   AS date,
  ROUND(temp_c   ,1) AS temp_c   ,
  ROUND(prcp_cm  ,1) AS prcp_cm  ,
  ROUND(wind_ms  ,1) AS wind_ms  ,
  ROUND(temp_ma8 ,1) AS temp_ma8 ,
  ROUND(prcp_ma8 ,1) AS prcp_ma8 ,
  ROUND(wind_ma8 ,1) AS wind_ma8 ,
  -- temperature differences
  ROUND(temp_diff_lag1,1) AS temp_ma8_diff_lag1,
  ROUND(temp_diff_lag2,1) AS temp_ma8_diff_lag2,
  ROUND(temp_diff_lag3,1) AS temp_ma8_diff_lag3,
  ROUND(temp_diff_lag4,1) AS temp_ma8_diff_lag4,
  ROUND(temp_diff_lag5,1) AS temp_ma8_diff_lag5,
  ROUND(temp_diff_lag6,1) AS temp_ma8_diff_lag6,
  ROUND(temp_diff_lag7,1) AS temp_ma8_diff_lag7,
  ROUND(temp_diff_lag8,1) AS temp_ma8_diff_lag8,
  -- precipitation differences
  ROUND(prcp_diff_lag1,1) AS prcp_ma8_diff_lag1,
  ROUND(prcp_diff_lag2,1) AS prcp_ma8_diff_lag2,
  ROUND(prcp_diff_lag3,1) AS prcp_ma8_diff_lag3,
  ROUND(prcp_diff_lag4,1) AS prcp_ma8_diff_lag4,
  ROUND(prcp_diff_lag5,1) AS prcp_ma8_diff_lag5,
  ROUND(prcp_diff_lag6,1) AS prcp_ma8_diff_lag6,
  ROUND(prcp_diff_lag7,1) AS prcp_ma8_diff_lag7,
  ROUND(prcp_diff_lag8,1) AS prcp_ma8_diff_lag8,
  -- wind‑speed differences
  ROUND(wind_diff_lag1,1) AS wind_ma8_diff_lag1,
  ROUND(wind_diff_lag2,1) AS wind_ma8_diff_lag2,
  ROUND(wind_diff_lag3,1) AS wind_ma8_diff_lag3,
  ROUND(wind_diff_lag4,1) AS wind_ma8_diff_lag4,
  ROUND(wind_diff_lag5,1) AS wind_ma8_diff_lag5,
  ROUND(wind_diff_lag6,1) AS wind_ma8_diff_lag6,
  ROUND(wind_diff_lag7,1) AS wind_ma8_diff_lag7,
  ROUND(wind_diff_lag8,1) AS wind_ma8_diff_lag8
FROM lagged
WHERE dt >= '2019-01-09'
ORDER BY dt;