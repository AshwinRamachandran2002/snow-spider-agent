WITH base AS (
  SELECT
    DATE(CONCAT(year,'-',mo,'-',da)) AS date,
    CASE WHEN temp = 9999.9 THEN NULL ELSE ROUND((temp - 32) * 5/9, 1) END        AS temp_c,
    CASE WHEN prcp = 99.99 THEN NULL ELSE ROUND(prcp * 2.54, 1) END               AS precip_cm,
    CASE WHEN CAST(wdsp AS FLOAT64) = 999.9 THEN NULL
         ELSE ROUND(CAST(wdsp AS FLOAT64) * 0.514444, 1) END                      AS wind_mps
  FROM `bigquery-public-data.noaa_gsod.gsod2019`
  WHERE stn  = '725290'
    AND wban = '14768'
    AND DATE(CONCAT(year,'-',mo,'-',da)) BETWEEN '2019-01-01' AND '2019-03-31'
),
ma AS (
  SELECT
    *,
    ROUND(AVG(temp_c)    OVER (ORDER BY date ROWS BETWEEN 7 PRECEDING AND CURRENT ROW), 1) AS temp_ma8,
    ROUND(AVG(precip_cm) OVER (ORDER BY date ROWS BETWEEN 7 PRECEDING AND CURRENT ROW), 1) AS precip_ma8,
    ROUND(AVG(wind_mps)  OVER (ORDER BY date ROWS BETWEEN 7 PRECEDING AND CURRENT ROW), 1) AS wind_ma8
  FROM base
)
SELECT
  date,
  temp_c,
  precip_cm,
  wind_mps,
  temp_ma8,
  precip_ma8,
  wind_ma8,
  ROUND(temp_ma8   - LAG(temp_ma8,1)   OVER (ORDER BY date), 1) AS temp_ma8_lag1_diff,
  ROUND(temp_ma8   - LAG(temp_ma8,2)   OVER (ORDER BY date), 1) AS temp_ma8_lag2_diff,
  ROUND(temp_ma8   - LAG(temp_ma8,3)   OVER (ORDER BY date), 1) AS temp_ma8_lag3_diff,
  ROUND(temp_ma8   - LAG(temp_ma8,4)   OVER (ORDER BY date), 1) AS temp_ma8_lag4_diff,
  ROUND(temp_ma8   - LAG(temp_ma8,5)   OVER (ORDER BY date), 1) AS temp_ma8_lag5_diff,
  ROUND(temp_ma8   - LAG(temp_ma8,6)   OVER (ORDER BY date), 1) AS temp_ma8_lag6_diff,
  ROUND(temp_ma8   - LAG(temp_ma8,7)   OVER (ORDER BY date), 1) AS temp_ma8_lag7_diff,
  ROUND(temp_ma8   - LAG(temp_ma8,8)   OVER (ORDER BY date), 1) AS temp_ma8_lag8_diff,
  ROUND(precip_ma8 - LAG(precip_ma8,1) OVER (ORDER BY date), 1) AS precip_ma8_lag1_diff,
  ROUND(precip_ma8 - LAG(precip_ma8,2) OVER (ORDER BY date), 1) AS precip_ma8_lag2_diff,
  ROUND(precip_ma8 - LAG(precip_ma8,3) OVER (ORDER BY date), 1) AS precip_ma8_lag3_diff,
  ROUND(precip_ma8 - LAG(precip_ma8,4) OVER (ORDER BY date), 1) AS precip_ma8_lag4_diff,
  ROUND(precip_ma8 - LAG(precip_ma8,5) OVER (ORDER BY date), 1) AS precip_ma8_lag5_diff,
  ROUND(precip_ma8 - LAG(precip_ma8,6) OVER (ORDER BY date), 1) AS precip_ma8_lag6_diff,
  ROUND(precip_ma8 - LAG(precip_ma8,7) OVER (ORDER BY date), 1) AS precip_ma8_lag7_diff,
  ROUND(precip_ma8 - LAG(precip_ma8,8) OVER (ORDER BY date), 1) AS precip_ma8_lag8_diff,
  ROUND(wind_ma8   - LAG(wind_ma8,1)   OVER (ORDER BY date), 1) AS wind_ma8_lag1_diff,
  ROUND(wind_ma8   - LAG(wind_ma8,2)   OVER (ORDER BY date), 1) AS wind_ma8_lag2_diff,
  ROUND(wind_ma8   - LAG(wind_ma8,3)   OVER (ORDER BY date), 1) AS wind_ma8_lag3_diff,
  ROUND(wind_ma8   - LAG(wind_ma8,4)   OVER (ORDER BY date), 1) AS wind_ma8_lag4_diff,
  ROUND(wind_ma8   - LAG(wind_ma8,5)   OVER (ORDER BY date), 1) AS wind_ma8_lag5_diff,
  ROUND(wind_ma8   - LAG(wind_ma8,6)   OVER (ORDER BY date), 1) AS wind_ma8_lag6_diff,
  ROUND(wind_ma8   - LAG(wind_ma8,7)   OVER (ORDER BY date), 1) AS wind_ma8_lag7_diff,
  ROUND(wind_ma8   - LAG(wind_ma8,8)   OVER (ORDER BY date), 1) AS wind_ma8_lag8_diff
FROM ma
WHERE date >= '2019-01-09'
ORDER BY date;