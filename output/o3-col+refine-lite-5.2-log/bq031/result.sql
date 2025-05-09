-- Daily Rochester (WBAN 14768) weather, 8‑day moving averages and 1–8‑day MA differences
WITH daily AS (   -- convert units and build DATE column
  SELECT
    PARSE_DATE('%Y%m%d', CONCAT(`year`,`mo`,`da`))                            AS dt,
    ROUND((`temp` - 32) * 5/9 , 1)                                            AS temp_c,          -- °F ➜ °C
    ROUND(NULLIF(`prcp`, 99.99) * 2.54 , 1)                                   AS prcp_cm,         -- inches ➜ cm
    ROUND(CAST(NULLIF(`wdsp`, '999.9') AS FLOAT64) * 0.514444 , 1)            AS wind_ms          -- knots ➜ m s‑1
  FROM `bigquery-public-data.noaa_gsod.gsod2019`
  WHERE `wban` = '14768'                                  -- Rochester, NY airport
    AND PARSE_DATE('%Y%m%d', CONCAT(`year`,`mo`,`da`))
        BETWEEN '2019-01-01' AND '2019-03-31'
),
ma AS (            -- 8‑day rolling means
  SELECT
    dt,
    temp_c, prcp_cm, wind_ms,
    ROUND(AVG(temp_c ) OVER (ORDER BY dt ROWS BETWEEN 7 PRECEDING AND CURRENT ROW),1) AS ma8_temp,
    ROUND(AVG(prcp_cm) OVER (ORDER BY dt ROWS BETWEEN 7 PRECEDING AND CURRENT ROW),1) AS ma8_prcp,
    ROUND(AVG(wind_ms) OVER (ORDER BY dt ROWS BETWEEN 7 PRECEDING AND CURRENT ROW),1) AS ma8_wind
  FROM daily
)
SELECT
  dt,
  temp_c, prcp_cm, wind_ms,
  ma8_temp, ma8_prcp, ma8_wind,

  -- temperature MA differences
  ROUND(ma8_temp - LAG(ma8_temp,1) OVER (ORDER BY dt),1) AS dtemp_lag1,
  ROUND(ma8_temp - LAG(ma8_temp,2) OVER (ORDER BY dt),1) AS dtemp_lag2,
  ROUND(ma8_temp - LAG(ma8_temp,3) OVER (ORDER BY dt),1) AS dtemp_lag3,
  ROUND(ma8_temp - LAG(ma8_temp,4) OVER (ORDER BY dt),1) AS dtemp_lag4,
  ROUND(ma8_temp - LAG(ma8_temp,5) OVER (ORDER BY dt),1) AS dtemp_lag5,
  ROUND(ma8_temp - LAG(ma8_temp,6) OVER (ORDER BY dt),1) AS dtemp_lag6,
  ROUND(ma8_temp - LAG(ma8_temp,7) OVER (ORDER BY dt),1) AS dtemp_lag7,
  ROUND(ma8_temp - LAG(ma8_temp,8) OVER (ORDER BY dt),1) AS dtemp_lag8,

  -- precipitation MA differences
  ROUND(ma8_prcp - LAG(ma8_prcp,1) OVER (ORDER BY dt),1) AS dprcp_lag1,
  ROUND(ma8_prcp - LAG(ma8_prcp,2) OVER (ORDER BY dt),1) AS dprcp_lag2,
  ROUND(ma8_prcp - LAG(ma8_prcp,3) OVER (ORDER BY dt),1) AS dprcp_lag3,
  ROUND(ma8_prcp - LAG(ma8_prcp,4) OVER (ORDER BY dt),1) AS dprcp_lag4,
  ROUND(ma8_prcp - LAG(ma8_prcp,5) OVER (ORDER BY dt),1) AS dprcp_lag5,
  ROUND(ma8_prcp - LAG(ma8_prcp,6) OVER (ORDER BY dt),1) AS dprcp_lag6,
  ROUND(ma8_prcp - LAG(ma8_prcp,7) OVER (ORDER BY dt),1) AS dprcp_lag7,
  ROUND(ma8_prcp - LAG(ma8_prcp,8) OVER (ORDER BY dt),1) AS dprcp_lag8,

  -- wind‑speed MA differences
  ROUND(ma8_wind - LAG(ma8_wind,1) OVER (ORDER BY dt),1) AS dwind_lag1,
  ROUND(ma8_wind - LAG(ma8_wind,2) OVER (ORDER BY dt),1) AS dwind_lag2,
  ROUND(ma8_wind - LAG(ma8_wind,3) OVER (ORDER BY dt),1) AS dwind_lag3,
  ROUND(ma8_wind - LAG(ma8_wind,4) OVER (ORDER BY dt),1) AS dwind_lag4,
  ROUND(ma8_wind - LAG(ma8_wind,5) OVER (ORDER BY dt),1) AS dwind_lag5,
  ROUND(ma8_wind - LAG(ma8_wind,6) OVER (ORDER BY dt),1) AS dwind_lag6,
  ROUND(ma8_wind - LAG(ma8_wind,7) OVER (ORDER BY dt),1) AS dwind_lag7,
  ROUND(ma8_wind - LAG(ma8_wind,8) OVER (ORDER BY dt),1) AS dwind_lag8

FROM ma
WHERE dt BETWEEN '2019-01-09' AND '2019-03-31'   -- first day with a full 8‑day window
ORDER BY dt;