/*  Daily Rochester‑NY weather (GSOD) with 8‑day moving‑averages & their lags  */
WITH rochester_station AS (               -- get the USAF id for Rochester, NY
  SELECT usaf AS stn
  FROM `bigquery-public-data.noaa_gsod.stations`
  WHERE UPPER(name) LIKE '%ROCHESTER%'
    AND state = 'NY'
  ORDER BY begin
  LIMIT 1
),
daily_raw AS (                            -- raw daily rows 1 Jan – 31 Mar 2019
  SELECT
    DATE(CONCAT(year,'-',mo,'-',da))                           AS dt,
    CAST(NULLIF(temp , 9999.9) AS FLOAT64)                    AS temp_f,
    CAST(NULLIF(prcp , 99.99 ) AS FLOAT64)                    AS prcp_in,
    CAST(NULLIF(wdsp , '999.9') AS FLOAT64)                   AS wdsp_kt
  FROM `bigquery-public-data.noaa_gsod.gsod2019` g
  JOIN rochester_station s
  ON  g.stn = s.stn
  WHERE DATE(CONCAT(year,'-',mo,'-',da)) BETWEEN '2019-01-01' AND '2019-03-31'
),
daily_conv AS (                           -- convert units & round
  SELECT
    dt                                                  AS date,
    ROUND( (temp_f - 32) * 5/9          , 1)            AS temperature_c,
    ROUND( prcp_in * 2.54               , 1)            AS precipitation_cm,
    ROUND( wdsp_kt * 0.514444           , 1)            AS windspeed_ms
  FROM daily_raw
),
daily_ma AS (                            -- 8‑day moving averages
  SELECT
    *,
    ROUND(AVG(temperature_c)   OVER(ORDER BY date ROWS BETWEEN 7 PRECEDING AND CURRENT ROW),1) AS ma_temp,
    ROUND(AVG(precipitation_cm)OVER(ORDER BY date ROWS BETWEEN 7 PRECEDING AND CURRENT ROW),1) AS ma_prcp,
    ROUND(AVG(windspeed_ms)    OVER(ORDER BY date ROWS BETWEEN 7 PRECEDING AND CURRENT ROW),1) AS ma_wind
  FROM daily_conv
)
SELECT
  date,
  temperature_c,
  precipitation_cm,
  windspeed_ms,
  ma_temp, ma_prcp, ma_wind,

  /*  lag‑difference columns: today’s MA minus MA from 1 … 8 days ago  */
  ROUND(ma_temp - LAG(ma_temp,1)  OVER(ORDER BY date),1) AS diff_temp_lag1,
  ROUND(ma_temp - LAG(ma_temp,2)  OVER(ORDER BY date),1) AS diff_temp_lag2,
  ROUND(ma_temp - LAG(ma_temp,3)  OVER(ORDER BY date),1) AS diff_temp_lag3,
  ROUND(ma_temp - LAG(ma_temp,4)  OVER(ORDER BY date),1) AS diff_temp_lag4,
  ROUND(ma_temp - LAG(ma_temp,5)  OVER(ORDER BY date),1) AS diff_temp_lag5,
  ROUND(ma_temp - LAG(ma_temp,6)  OVER(ORDER BY date),1) AS diff_temp_lag6,
  ROUND(ma_temp - LAG(ma_temp,7)  OVER(ORDER BY date),1) AS diff_temp_lag7,
  ROUND(ma_temp - LAG(ma_temp,8)  OVER(ORDER BY date),1) AS diff_temp_lag8,

  ROUND(ma_prcp - LAG(ma_prcp,1)  OVER(ORDER BY date),1) AS diff_prcp_lag1,
  ROUND(ma_prcp - LAG(ma_prcp,2)  OVER(ORDER BY date),1) AS diff_prcp_lag2,
  ROUND(ma_prcp - LAG(ma_prcp,3)  OVER(ORDER BY date),1) AS diff_prcp_lag3,
  ROUND(ma_prcp - LAG(ma_prcp,4)  OVER(ORDER BY date),1) AS diff_prcp_lag4,
  ROUND(ma_prcp - LAG(ma_prcp,5)  OVER(ORDER BY date),1) AS diff_prcp_lag5,
  ROUND(ma_prcp - LAG(ma_prcp,6)  OVER(ORDER BY date),1) AS diff_prcp_lag6,
  ROUND(ma_prcp - LAG(ma_prcp,7)  OVER(ORDER BY date),1) AS diff_prcp_lag7,
  ROUND(ma_prcp - LAG(ma_prcp,8)  OVER(ORDER BY date),1) AS diff_prcp_lag8,

  ROUND(ma_wind - LAG(ma_wind,1)  OVER(ORDER BY date),1) AS diff_wind_lag1,
  ROUND(ma_wind - LAG(ma_wind,2)  OVER(ORDER BY date),1) AS diff_wind_lag2,
  ROUND(ma_wind - LAG(ma_wind,3)  OVER(ORDER BY date),1) AS diff_wind_lag3,
  ROUND(ma_wind - LAG(ma_wind,4)  OVER(ORDER BY date),1) AS diff_wind_lag4,
  ROUND(ma_wind - LAG(ma_wind,5)  OVER(ORDER BY date),1) AS diff_wind_lag5,
  ROUND(ma_wind - LAG(ma_wind,6)  OVER(ORDER BY date),1) AS diff_wind_lag6,
  ROUND(ma_wind - LAG(ma_wind,7)  OVER(ORDER BY date),1) AS diff_wind_lag7,
  ROUND(ma_wind - LAG(ma_wind,8)  OVER(ORDER BY date),1) AS diff_wind_lag8
FROM daily_ma
WHERE date >= '2019-01-09'   -- first date with a full 8‑day window
ORDER BY date;