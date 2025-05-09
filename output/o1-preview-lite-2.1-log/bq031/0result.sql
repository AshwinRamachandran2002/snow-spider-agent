SELECT
  date,
  ROUND(temp_celsius, 4) AS Temperature_C,
  ROUND(precip_cm, 4) AS Precipitation_cm,
  ROUND(wind_mps, 4) AS Wind_Speed_mps,
  ROUND(mov_avg_temp_c, 4) AS Moving_Avg_Temp_C,
  ROUND(mov_avg_precip_cm, 4) AS Moving_Avg_Precip_cm,
  ROUND(mov_avg_wind_mps, 4) AS Moving_Avg_Wind_Speed_mps,
  ROUND(mov_avg_temp_c - LAG(mov_avg_temp_c, 8) OVER (ORDER BY date), 4) AS Difference_MA_Temp_C,
  ROUND(mov_avg_precip_cm - LAG(mov_avg_precip_cm, 8) OVER (ORDER BY date), 4) AS Difference_MA_Precip_cm,
  ROUND(mov_avg_wind_mps - LAG(mov_avg_wind_mps, 8) OVER (ORDER BY date), 4) AS Difference_MA_Wind_Speed_mps
FROM (
  SELECT
    date,
    AVG(temp_celsius) AS temp_celsius,
    AVG(precip_cm) AS precip_cm,
    AVG(wind_mps) AS wind_mps,
    AVG(AVG(temp_celsius)) OVER (ORDER BY date ROWS BETWEEN 7 PRECEDING AND CURRENT ROW) AS mov_avg_temp_c,
    AVG(AVG(precip_cm)) OVER (ORDER BY date ROWS BETWEEN 7 PRECEDING AND CURRENT ROW) AS mov_avg_precip_cm,
    AVG(AVG(wind_mps)) OVER (ORDER BY date ROWS BETWEEN 7 PRECEDING AND CURRENT ROW) AS mov_avg_wind_mps
  FROM (
    SELECT
      DATE(CAST(g.year AS INT64), CAST(g.mo AS INT64), CAST(g.da AS INT64)) AS date,
      (g.temp - 32) * 5 / 9 AS temp_celsius,
      g.prcp * 2.54 AS precip_cm,
      SAFE_CAST(g.wdsp AS FLOAT64) * 0.514444 AS wind_mps
    FROM
      `bigquery-public-data.noaa_gsod.gsod2019` AS g
    JOIN
      `bigquery-public-data.noaa_gsod.stations` AS s
    ON
      g.stn = s.usaf AND g.wban = s.wban
    WHERE
      LOWER(s.name) LIKE '%rochester%' AND s.state = 'NY'
      AND DATE(CAST(g.year AS INT64), CAST(g.mo AS INT64), CAST(g.da AS INT64)) >= '2019-01-01'
      AND CAST(g.mo AS INT64) IN (1, 2, 3)
      AND g.temp < 9999.9
      AND g.prcp < 99.99
      AND SAFE_CAST(g.wdsp AS FLOAT64) < 999.9
  )
  GROUP BY date
)
WHERE date >= '2019-01-09'
ORDER BY date ASC;