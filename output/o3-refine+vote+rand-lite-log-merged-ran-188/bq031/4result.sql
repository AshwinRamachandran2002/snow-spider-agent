-- Rochester (NY) daily weather – Jan 1 – Mar 31 2019
--  • variables converted to metric
--  • 8-day moving averages (MA8)
--  • MA8 day-to-day differences for lags 1-8

WITH daily AS (                       -- 1. raw → metric
  SELECT
    DATE(CAST(year AS INT64),
         CAST(mo   AS INT64),
         CAST(da   AS INT64))                AS day,
    (temp - 32) * 5/9                        AS temp_c,            -- °F → °C
    prcp * 2.54                              AS prcp_cm,           -- inch → cm
    SAFE_CAST(wdsp AS FLOAT64) * 0.514444    AS wind_ms            -- kt  → m s-¹
  FROM `bigquery-public-data.noaa_gsod.gsod2019`
  WHERE stn  = '725290'      -- Greater Rochester International AP
    AND wban = '14768'
    AND DATE(CAST(year AS INT64),CAST(mo AS INT64),CAST(da AS INT64))
        BETWEEN '2019-01-01' AND '2019-03-31'
),
ma8 AS (                           -- 2. 8-day moving averages
  SELECT
    day,
    temp_c, prcp_cm, wind_ms,
    AVG(temp_c)  OVER w AS ma8_temp,
    AVG(prcp_cm) OVER w AS ma8_prcp,
    AVG(wind_ms) OVER w AS ma8_wind
  FROM daily
  WINDOW w AS (ORDER BY day ROWS BETWEEN 7 PRECEDING AND CURRENT ROW)
),
diffs AS (                         -- 3. MA8 lag differences
  SELECT
    day,
    ROUND(temp_c ,1)               AS temp_c,
    ROUND(prcp_cm,1)               AS prcp_cm,
    ROUND(wind_ms,1)               AS wind_ms,
    ROUND(ma8_temp,1)              AS ma8_temp,
    ROUND(ma8_prcp,1)              AS ma8_prcp,
    ROUND(ma8_wind,1)              AS ma8_wind,

    -- temperature MA8 differences
    ROUND(ma8_temp - LAG(ma8_temp,1) OVER o ,1) AS d_temp_lag1,
    ROUND(ma8_temp - LAG(ma8_temp,2) OVER o ,1) AS d_temp_lag2,
    ROUND(ma8_temp - LAG(ma8_temp,3) OVER o ,1) AS d_temp_lag3,
    ROUND(ma8_temp - LAG(ma8_temp,4) OVER o ,1) AS d_temp_lag4,
    ROUND(ma8_temp - LAG(ma8_temp,5) OVER o ,1) AS d_temp_lag5,
    ROUND(ma8_temp - LAG(ma8_temp,6) OVER o ,1) AS d_temp_lag6,
    ROUND(ma8_temp - LAG(ma8_temp,7) OVER o ,1) AS d_temp_lag7,
    ROUND(ma8_temp - LAG(ma8_temp,8) OVER o ,1) AS d_temp_lag8,

    -- precipitation MA8 differences
    ROUND(ma8_prcp - LAG(ma8_prcp,1) OVER o ,1) AS d_prcp_lag1,
    ROUND(ma8_prcp - LAG(ma8_prcp,2) OVER o ,1) AS d_prcp_lag2,
    ROUND(ma8_prcp - LAG(ma8_prcp,3) OVER o ,1) AS d_prcp_lag3,
    ROUND(ma8_prcp - LAG(ma8_prcp,4) OVER o ,1) AS d_prcp_lag4,
    ROUND(ma8_prcp - LAG(ma8_prcp,5) OVER o ,1) AS d_prcp_lag5,
    ROUND(ma8_prcp - LAG(ma8_prcp,6) OVER o ,1) AS d_prcp_lag6,
    ROUND(ma8_prcp - LAG(ma8_prcp,7) OVER o ,1) AS d_prcp_lag7,
    ROUND(ma8_prcp - LAG(ma8_prcp,8) OVER o ,1) AS d_prcp_lag8,

    -- wind-speed MA8 differences
    ROUND(ma8_wind - LAG(ma8_wind,1) OVER o ,1) AS d_wind_lag1,
    ROUND(ma8_wind - LAG(ma8_wind,2) OVER o ,1) AS d_wind_lag2,
    ROUND(ma8_wind - LAG(ma8_wind,3) OVER o ,1) AS d_wind_lag3,
    ROUND(ma8_wind - LAG(ma8_wind,4) OVER o ,1) AS d_wind_lag4,
    ROUND(ma8_wind - LAG(ma8_wind,5) OVER o ,1) AS d_wind_lag5,
    ROUND(ma8_wind - LAG(ma8_wind,6) OVER o ,1) AS d_wind_lag6,
    ROUND(ma8_wind - LAG(ma8_wind,7) OVER o ,1) AS d_wind_lag7,
    ROUND(ma8_wind - LAG(ma8_wind,8) OVER o ,1) AS d_wind_lag8
  FROM ma8
  WINDOW o AS (ORDER BY day)
)

SELECT *
FROM diffs
WHERE day >= '2019-01-09'      -- first day with a complete 8-day window
ORDER BY day;