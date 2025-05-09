SELECT
  `date` AS Date,
  temperature_c AS Temperature_C,
  precipitation_cm AS Precipitation_cm,
  wind_speed_mps AS Wind_Speed_mps,
  moving_avg_temp_c AS Moving_Avg_Temp_C,
  moving_avg_precip_cm AS Moving_Avg_Precip_cm,
  moving_avg_wind_speed_mps AS Moving_Avg_Wind_Speed_mps,
  ROUND(moving_avg_temp_c - LAG(moving_avg_temp_c, 8) OVER (ORDER BY `date`), 1) AS Difference_MA_Temp_C,
  ROUND(moving_avg_precip_cm - LAG(moving_avg_precip_cm, 8) OVER (ORDER BY `date`), 1) AS Difference_MA_Precip_cm,
  ROUND(moving_avg_wind_speed_mps - LAG(moving_avg_wind_speed_mps, 8) OVER (ORDER BY `date`), 1) AS Difference_MA_Wind_Speed_mps
FROM (
  SELECT
    `date`,
    temperature_c,
    precipitation_cm,
    wind_speed_mps,
    ROUND(AVG(temperature_c) OVER (ORDER BY `date` ROWS BETWEEN 7 PRECEDING AND CURRENT ROW), 1) AS moving_avg_temp_c,
    ROUND(AVG(precipitation_cm) OVER (ORDER BY `date` ROWS BETWEEN 7 PRECEDING AND CURRENT ROW), 1) AS moving_avg_precip_cm,
    ROUND(AVG(wind_speed_mps) OVER (ORDER BY `date` ROWS BETWEEN 7 PRECEDING AND CURRENT ROW), 1) AS moving_avg_wind_speed_mps
  FROM (
    SELECT
      PARSE_DATE('%Y%m%d', CONCAT(g.`year`, LPAD(g.mo, 2, '0'), LPAD(g.da, 2, '0'))) AS `date`,
      ROUND((g.temp - 32) * 5/9, 1) AS temperature_c,
      ROUND(g.prcp * 2.54, 1) AS precipitation_cm,
      ROUND(CAST(g.wdsp AS FLOAT64) * 0.514444, 1) AS wind_speed_mps
    FROM `bigquery-public-data.noaa_gsod.gsod2019` AS g
    JOIN `bigquery-public-data.noaa_gsod.stations` AS s
    ON g.stn = s.usaf
    WHERE
      LOWER(s.name) LIKE '%rochester%' AND
      s.state = 'NY' AND
      g.temp < 9999.9 AND
      g.prcp < 99.99 AND
      CAST(g.wdsp AS FLOAT64) < 999.9 AND
      PARSE_DATE('%Y%m%d', CONCAT(g.`year`, LPAD(g.mo, 2, '0'), LPAD(g.da, 2, '0'))) >= '2019-01-09' AND
      g.mo IN ('01', '02', '03')
  )
)
ORDER BY `date` ASC;