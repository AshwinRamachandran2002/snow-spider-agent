-- Rochester (New York) daily weather with 8‑day moving averages and lag‑1 … lag‑8
WITH rochester_stations AS (           -- pick Rochester, NY stations
  SELECT usaf, wban
  FROM   `bigquery-public-data.noaa_gsod.stations`
  WHERE  state = 'NY'
    AND  UPPER(name) LIKE '%ROCHESTER%'
),

daily AS (                             -- raw daily values, converted to metric
  SELECT
    DATE(CONCAT(gs.year,'-',gs.mo,'-',gs.da))                        AS day,
    (gs.temp - 32) * 5/9                                             AS temp_c,      -- °C
    gs.prcp * 2.54                                                   AS prcp_cm,     -- cm
    CAST(NULLIF(gs.wdsp,'999.9') AS FLOAT64) * 0.514444             AS wind_ms      -- m s‑1
  FROM   `bigquery-public-data.noaa_gsod.gsod2019` gs
  JOIN   rochester_stations rs
         ON gs.stn  = rs.usaf
        AND gs.wban = rs.wban
  WHERE  DATE(CONCAT(gs.year,'-',gs.mo,'-',gs.da))
         BETWEEN '2019-01-01' AND '2019-03-31'
),

metrics AS (                         -- round the raw daily numbers
  SELECT
    day,
    ROUND(temp_c ,1) AS temp_c,
    ROUND(prcp_cm,1) AS prcp_cm,
    ROUND(wind_ms,1) AS wind_ms
  FROM daily
),

ma AS (                              -- 8‑day moving averages (current + 7 prior)
  SELECT
    m.*,
    ROUND(AVG(temp_c ) OVER(ORDER BY day ROWS BETWEEN 7 PRECEDING AND CURRENT ROW),1) AS ma_temp,
    ROUND(AVG(prcp_cm) OVER(ORDER BY day ROWS BETWEEN 7 PRECEDING AND CURRENT ROW),1) AS ma_prcp,
    ROUND(AVG(wind_ms) OVER(ORDER BY day ROWS BETWEEN 7 PRECEDING AND CURRENT ROW),1) AS ma_wind
  FROM metrics m
)

SELECT
  day,
  temp_c , prcp_cm , wind_ms ,          -- daily values
  ma_temp , ma_prcp , ma_wind ,         -- 8‑day moving avgs
  -- temperature MA differences
  ROUND(ma_temp - LAG(ma_temp,1) OVER(ORDER BY day),1) AS temp_diff_lag1,
  ROUND(ma_temp - LAG(ma_temp,2) OVER(ORDER BY day),1) AS temp_diff_lag2,
  ROUND(ma_temp - LAG(ma_temp,3) OVER(ORDER BY day),1) AS temp_diff_lag3,
  ROUND(ma_temp - LAG(ma_temp,4) OVER(ORDER BY day),1) AS temp_diff_lag4,
  ROUND(ma_temp - LAG(ma_temp,5) OVER(ORDER BY day),1) AS temp_diff_lag5,
  ROUND(ma_temp - LAG(ma_temp,6) OVER(ORDER BY day),1) AS temp_diff_lag6,
  ROUND(ma_temp - LAG(ma_temp,7) OVER(ORDER BY day),1) AS temp_diff_lag7,
  ROUND(ma_temp - LAG(ma_temp,8) OVER(ORDER BY day),1) AS temp_diff_lag8,
  -- precipitation MA differences
  ROUND(ma_prcp - LAG(ma_prcp,1) OVER(ORDER BY day),1) AS prcp_diff_lag1,
  ROUND(ma_prcp - LAG(ma_prcp,2) OVER(ORDER BY day),1) AS prcp_diff_lag2,
  ROUND(ma_prcp - LAG(ma_prcp,3) OVER(ORDER BY day),1) AS prcp_diff_lag3,
  ROUND(ma_prcp - LAG(ma_prcp,4) OVER(ORDER BY day),1) AS prcp_diff_lag4,
  ROUND(ma_prcp - LAG(ma_prcp,5) OVER(ORDER BY day),1) AS prcp_diff_lag5,
  ROUND(ma_prcp - LAG(ma_prcp,6) OVER(ORDER BY day),1) AS prcp_diff_lag6,
  ROUND(ma_prcp - LAG(ma_prcp,7) OVER(ORDER BY day),1) AS prcp_diff_lag7,
  ROUND(ma_prcp - LAG(ma_prcp,8) OVER(ORDER BY day),1) AS prcp_diff_lag8,
  -- wind‑speed MA differences
  ROUND(ma_wind - LAG(ma_wind,1) OVER(ORDER BY day),1) AS wind_diff_lag1,
  ROUND(ma_wind - LAG(ma_wind,2) OVER(ORDER BY day),1) AS wind_diff_lag2,
  ROUND(ma_wind - LAG(ma_wind,3) OVER(ORDER BY day),1) AS wind_diff_lag3,
  ROUND(ma_wind - LAG(ma_wind,4) OVER(ORDER BY day),1) AS wind_diff_lag4,
  ROUND(ma_wind - LAG(ma_wind,5) OVER(ORDER BY day),1) AS wind_diff_lag5,
  ROUND(ma_wind - LAG(ma_wind,6) OVER(ORDER BY day),1) AS wind_diff_lag6,
  ROUND(ma_wind - LAG(ma_wind,7) OVER(ORDER BY day),1) AS wind_diff_lag7,
  ROUND(ma_wind - LAG(ma_wind,8) OVER(ORDER BY day),1) AS wind_diff_lag8
FROM  ma
WHERE day >= '2019-01-09'            -- first date with a full 8‑day window
ORDER BY day;