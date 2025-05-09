SELECT
  COALESCE(epa.city_name, openaq.city) AS City,
  ABS(epa.avg_pm25 - openaq.avg_pm25) AS Difference_in_PM25
FROM
  (
    SELECT
      ROUND(latitude, 2) AS lat_round,
      ROUND(longitude, 2) AS lon_round,
      ANY_VALUE(city_name) AS city_name,
      AVG(arithmetic_mean) AS avg_pm25
    FROM
      `bigquery-public-data.epa_historical_air_quality.pm25_frm_daily_summary`
    WHERE
      LOWER(parameter_name) LIKE '%pm2.5%'
      AND date_local BETWEEN '2019-01-01' AND '2019-12-31'
    GROUP BY
      lat_round, lon_round
  ) AS epa
JOIN
  (
    SELECT
      ROUND(latitude, 2) AS lat_round,
      ROUND(longitude, 2) AS lon_round,
      ANY_VALUE(city) AS city,
      AVG(value) AS avg_pm25
    FROM
      `bigquery-public-data.openaq.global_air_quality`
    WHERE
      LOWER(pollutant) = 'pm25'
      AND timestamp BETWEEN '2019-01-01' AND '2019-12-31'
      AND country = 'US'
    GROUP BY
      lat_round, lon_round
  ) AS openaq
ON
  epa.lat_round = openaq.lat_round
  AND epa.lon_round = openaq.lon_round
ORDER BY
  Difference_in_PM25 DESC
LIMIT 3;