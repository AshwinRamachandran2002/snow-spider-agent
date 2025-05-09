SELECT
  date,
  temp_celsius,
  precip_cm,
  wind_speed_mps,
  mov_avg_temp_celsius,
  mov_avg_precip_cm,
  mov_avg_wind_speed_mps,
  ROUND(mov_avg_temp_celsius - LAG(mov_avg_temp_celsius, 8) OVER (ORDER BY date), 1) AS diff_ma_temp_celsius,
  ROUND(mov_avg_precip_cm - LAG(mov_avg_precip_cm, 8) OVER (ORDER BY date), 1) AS diff_ma_precip_cm,
  ROUND(mov_avg_wind_speed_mps - LAG(mov_avg_wind_speed_mps, 8) OVER (ORDER BY date), 1) AS diff_ma_wind_speed_mps
FROM (
  SELECT
    DATE(CAST(year AS INT64), CAST(mo AS INT64), CAST(da AS INT64)) AS date,
    ROUND((CAST(temp AS FLOAT64) - 32) * 5/9, 1) AS temp_celsius,
    ROUND(CAST(prcp AS FLOAT64) * 2.54, 1) AS precip_cm,
    ROUND(CAST(wdsp AS FLOAT64) * 0.514444, 1) AS wind_speed_mps,
    ROUND(
      AVG((CAST(temp AS FLOAT64) - 32) * 5/9) OVER (
        ORDER BY DATE(CAST(year AS INT64), CAST(mo AS INT64), CAST(da AS INT64))
        ROWS BETWEEN 7 PRECEDING AND CURRENT ROW
      ), 1
    ) AS mov_avg_temp_celsius,
    ROUND(
      AVG(CAST(prcp AS FLOAT64) * 2.54) OVER (
        ORDER BY DATE(CAST(year AS INT64), CAST(mo AS INT64), CAST(da AS INT64))
        ROWS BETWEEN 7 PRECEDING AND CURRENT ROW
      ), 1
    ) AS mov_avg_precip_cm,
    ROUND(
      AVG(CAST(wdsp AS FLOAT64) * 0.514444) OVER (
        ORDER BY DATE(CAST(year AS INT64), CAST(mo AS INT64), CAST(da AS INT64))
        ROWS BETWEEN 7 PRECEDING AND CURRENT ROW
      ), 1
    ) AS mov_avg_wind_speed_mps
  FROM `bigquery-public-data.noaa_gsod.gsod2019`
  WHERE stn = '725290' AND wban = '14768'
    AND DATE(CAST(year AS INT64), CAST(mo AS INT64), CAST(da AS INT64)) >= '2019-01-01'
    AND DATE(CAST(year AS INT64), CAST(mo AS INT64), CAST(da AS INT64)) <= '2019-03-31'
)
WHERE date >= '2019-01-09'
ORDER BY date ASC;