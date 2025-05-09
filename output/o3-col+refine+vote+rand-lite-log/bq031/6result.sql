-- Daily weather for Rochester (USAF 725290 / WBAN 14768)
-- Jan-01 – Mar-31 2019 with 8-day moving-averages and
-- lag-1 … lag-8 differences (all values rounded to 0.1)

WITH daily AS (         -- 1. raw daily data, unit conversion
  SELECT
    DATE(CONCAT(year,'-',mo,'-',da))                           AS d,
    ROUND( (temp - 32) * 5/9 ,1)                              AS temp_c,            -- °F → °C
    ROUND( CASE WHEN prcp < 99 THEN prcp * 2.54 END ,1)       AS prcp_cm,           -- in → cm
    ROUND( CAST(wdsp AS FLOAT64) * 0.514444 ,1)               AS wind_ms            -- kt → m s-1
  FROM `bigquery-public-data.noaa_gsod.gsod2019`
  WHERE stn  = '725290'      -- Rochester NY airport
    AND wban = '14768'
    AND DATE(CONCAT(year,'-',mo,'-',da)) BETWEEN '2019-01-01' AND '2019-03-31'
),

ma AS (                   -- 2. 8-day moving averages (current + 7 back)
  SELECT
    d,
    temp_c,
    prcp_cm,
    wind_ms,
    ROUND( AVG(temp_c)  OVER(ORDER BY d ROWS BETWEEN 7 PRECEDING AND CURRENT ROW),1) AS ma8_temp,
    ROUND( AVG(prcp_cm) OVER(ORDER BY d ROWS BETWEEN 7 PRECEDING AND CURRENT ROW),1) AS ma8_prcp,
    ROUND( AVG(wind_ms) OVER(ORDER BY d ROWS BETWEEN 7 PRECEDING AND CURRENT ROW),1) AS ma8_wind
  FROM daily
),

lagdiff AS (              -- 3. differences: today minus lag-1 … lag-8
  SELECT
    *,
    -- temperature lags
    ROUND(ma8_temp - LAG(ma8_temp,1) OVER(ORDER BY d),1) AS dt1,
    ROUND(ma8_temp - LAG(ma8_temp,2) OVER(ORDER BY d),1) AS dt2,
    ROUND(ma8_temp - LAG(ma8_temp,3) OVER(ORDER BY d),1) AS dt3,
    ROUND(ma8_temp - LAG(ma8_temp,4) OVER(ORDER BY d),1) AS dt4,
    ROUND(ma8_temp - LAG(ma8_temp,5) OVER(ORDER BY d),1) AS dt5,
    ROUND(ma8_temp - LAG(ma8_temp,6) OVER(ORDER BY d),1) AS dt6,
    ROUND(ma8_temp - LAG(ma8_temp,7) OVER(ORDER BY d),1) AS dt7,
    ROUND(ma8_temp - LAG(ma8_temp,8) OVER(ORDER BY d),1) AS dt8,

    -- precipitation lags
    ROUND(ma8_prcp - LAG(ma8_prcp,1) OVER(ORDER BY d),1) AS dp1,
    ROUND(ma8_prcp - LAG(ma8_prcp,2) OVER(ORDER BY d),1) AS dp2,
    ROUND(ma8_prcp - LAG(ma8_prcp,3) OVER(ORDER BY d),1) AS dp3,
    ROUND(ma8_prcp - LAG(ma8_prcp,4) OVER(ORDER BY d),1) AS dp4,
    ROUND(ma8_prcp - LAG(ma8_prcp,5) OVER(ORDER BY d),1) AS dp5,
    ROUND(ma8_prcp - LAG(ma8_prcp,6) OVER(ORDER BY d),1) AS dp6,
    ROUND(ma8_prcp - LAG(ma8_prcp,7) OVER(ORDER BY d),1) AS dp7,
    ROUND(ma8_prcp - LAG(ma8_prcp,8) OVER(ORDER BY d),1) AS dp8,

    -- wind lags
    ROUND(ma8_wind - LAG(ma8_wind,1) OVER(ORDER BY d),1) AS dw1,
    ROUND(ma8_wind - LAG(ma8_wind,2) OVER(ORDER BY d),1) AS dw2,
    ROUND(ma8_wind - LAG(ma8_wind,3) OVER(ORDER BY d),1) AS dw3,
    ROUND(ma8_wind - LAG(ma8_wind,4) OVER(ORDER BY d),1) AS dw4,
    ROUND(ma8_wind - LAG(ma8_wind,5) OVER(ORDER BY d),1) AS dw5,
    ROUND(ma8_wind - LAG(ma8_wind,6) OVER(ORDER BY d),1) AS dw6,
    ROUND(ma8_wind - LAG(ma8_wind,7) OVER(ORDER BY d),1) AS dw7,
    ROUND(ma8_wind - LAG(ma8_wind,8) OVER(ORDER BY d),1) AS dw8
  FROM ma
)

-- 4. show results (first complete window is 9 Jan 2019)
SELECT *
FROM lagdiff
WHERE d >= '2019-01-09'
ORDER BY d;