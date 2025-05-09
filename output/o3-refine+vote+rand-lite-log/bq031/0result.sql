-- Daily weather for Rochester (NY) 1 Jan – 31 Mar 2019
WITH rochester_stations AS (
  SELECT
    usaf  AS stn,
    wban
  FROM `bigquery-public-data.noaa_gsod.stations`
  WHERE state = 'NY'
    AND LOWER(name) LIKE '%rochester%'
),
daily_raw AS (
  SELECT
    PARSE_DATE('%Y-%m-%d', CONCAT(g.year,'-',g.mo,'-',g.da)) AS dt,
    CAST(g.temp AS FLOAT64)  AS temp_f,
    CAST(g.prcp AS FLOAT64)  AS prcp_in,
    CAST(g.wdsp AS FLOAT64)  AS wdsp_kt
  FROM `bigquery-public-data.noaa_gsod.gsod2019` AS g
  JOIN rochester_stations AS s
  ON  g.stn = s.stn
  AND g.wban = s.wban
  WHERE CONCAT(g.year,g.mo,g.da) IS NOT NULL
    AND PARSE_DATE('%Y-%m-%d', CONCAT(g.year,'-',g.mo,'-',g.da))
        BETWEEN '2019-01-01' AND '2019-03-31'
),
daily AS (
  SELECT
    dt,
    -- convert units & clean missing codes
    ROUND(
      CASE WHEN temp_f IS NULL OR temp_f >= 9999 THEN NULL
           ELSE (temp_f - 32)*5/9 END ,1)               AS temp_c,
    ROUND(
      CASE WHEN prcp_in IS NULL OR prcp_in >= 99 THEN NULL
           ELSE prcp_in * 2.54 END ,1)                  AS prcp_cm,
    ROUND(
      CASE WHEN wdsp_kt IS NULL OR wdsp_kt >= 999 THEN NULL
           ELSE wdsp_kt * 0.514444 END ,1)              AS wind_ms
  FROM daily_raw
),
ma AS (
  SELECT
    dt,
    temp_c, prcp_cm, wind_ms,
    ROUND(AVG(temp_c ) OVER (ORDER BY dt ROWS BETWEEN 7 PRECEDING AND CURRENT ROW),1) AS ma_temp_c,
    ROUND(AVG(prcp_cm) OVER (ORDER BY dt ROWS BETWEEN 7 PRECEDING AND CURRENT ROW),1) AS ma_prcp_cm,
    ROUND(AVG(wind_ms) OVER (ORDER BY dt ROWS BETWEEN 7 PRECEDING AND CURRENT ROW),1) AS ma_wind_ms
  FROM daily
)
SELECT
  dt                                           AS date,
  temp_c                                       AS temperature_c,
  prcp_cm                                      AS precipitation_cm,
  wind_ms                                      AS wind_ms,
  ma_temp_c, ma_prcp_cm, ma_wind_ms,

  /* temperature MA differences */
  ROUND(ma_temp_c - LAG(ma_temp_c,1) OVER(ORDER BY dt),1)  AS temp_ma_diff_lag1,
  ROUND(ma_temp_c - LAG(ma_temp_c,2) OVER(ORDER BY dt),1)  AS temp_ma_diff_lag2,
  ROUND(ma_temp_c - LAG(ma_temp_c,3) OVER(ORDER BY dt),1)  AS temp_ma_diff_lag3,
  ROUND(ma_temp_c - LAG(ma_temp_c,4) OVER(ORDER BY dt),1)  AS temp_ma_diff_lag4,
  ROUND(ma_temp_c - LAG(ma_temp_c,5) OVER(ORDER BY dt),1)  AS temp_ma_diff_lag5,
  ROUND(ma_temp_c - LAG(ma_temp_c,6) OVER(ORDER BY dt),1)  AS temp_ma_diff_lag6,
  ROUND(ma_temp_c - LAG(ma_temp_c,7) OVER(ORDER BY dt),1)  AS temp_ma_diff_lag7,
  ROUND(ma_temp_c - LAG(ma_temp_c,8) OVER(ORDER BY dt),1)  AS temp_ma_diff_lag8,

  /* precipitation MA differences */
  ROUND(ma_prcp_cm - LAG(ma_prcp_cm,1) OVER(ORDER BY dt),1) AS prcp_ma_diff_lag1,
  ROUND(ma_prcp_cm - LAG(ma_prcp_cm,2) OVER(ORDER BY dt),1) AS prcp_ma_diff_lag2,
  ROUND(ma_prcp_cm - LAG(ma_prcp_cm,3) OVER(ORDER BY dt),1) AS prcp_ma_diff_lag3,
  ROUND(ma_prcp_cm - LAG(ma_prcp_cm,4) OVER(ORDER BY dt),1) AS prcp_ma_diff_lag4,
  ROUND(ma_prcp_cm - LAG(ma_prcp_cm,5) OVER(ORDER BY dt),1) AS prcp_ma_diff_lag5,
  ROUND(ma_prcp_cm - LAG(ma_prcp_cm,6) OVER(ORDER BY dt),1) AS prcp_ma_diff_lag6,
  ROUND(ma_prcp_cm - LAG(ma_prcp_cm,7) OVER(ORDER BY dt),1) AS prcp_ma_diff_lag7,
  ROUND(ma_prcp_cm - LAG(ma_prcp_cm,8) OVER(ORDER BY dt),1) AS prcp_ma_diff_lag8,

  /* wind‑speed MA differences */
  ROUND(ma_wind_ms - LAG(ma_wind_ms,1) OVER(ORDER BY dt),1) AS wind_ma_diff_lag1,
  ROUND(ma_wind_ms - LAG(ma_wind_ms,2) OVER(ORDER BY dt),1) AS wind_ma_diff_lag2,
  ROUND(ma_wind_ms - LAG(ma_wind_ms,3) OVER(ORDER BY dt),1) AS wind_ma_diff_lag3,
  ROUND(ma_wind_ms - LAG(ma_wind_ms,4) OVER(ORDER BY dt),1) AS wind_ma_diff_lag4,
  ROUND(ma_wind_ms - LAG(ma_wind_ms,5) OVER(ORDER BY dt),1) AS wind_ma_diff_lag5,
  ROUND(ma_wind_ms - LAG(ma_wind_ms,6) OVER(ORDER BY dt),1) AS wind_ma_diff_lag6,
  ROUND(ma_wind_ms - LAG(ma_wind_ms,7) OVER(ORDER BY dt),1) AS wind_ma_diff_lag7,
  ROUND(ma_wind_ms - LAG(ma_wind_ms,8) OVER(ORDER BY dt),1) AS wind_ma_diff_lag8

FROM ma
WHERE dt >= '2019-01-09'          -- first day with a full 8‑day window
ORDER BY dt;