WITH epa AS (
  SELECT
    ROUND(latitude, 1) AS lat,
    ROUND(longitude, 1) AS lon,
    AVG(arithmetic_mean) AS avg_pm25_1997
  FROM
    `bigquery-public-data.epa_historical_air_quality.pm25_frm_daily_summary`
  WHERE
    EXTRACT(YEAR FROM date_local) = 1997
    AND parameter_name = 'PM2.5 - Local Conditions'
    AND units_of_measure = 'Micrograms/cubic meter (LC)'
  GROUP BY
    lat, lon
),
openaq AS (
  SELECT
    ROUND(latitude, 1) AS lat,
    ROUND(longitude, 1) AS lon,
    AVG(value) AS avg_pm25_2020,
    ANY_VALUE(city) AS City
  FROM
    `bigquery-public-data.openaq.global_air_quality`
  WHERE
    EXTRACT(YEAR FROM timestamp) = 2020
    AND pollutant = 'pm25'
    AND country = 'US'
  GROUP BY
    lat, lon
)
SELECT
  openaq.City,
  ROUND(epa.avg_pm25_1997 - openaq.avg_pm25_2020, 4) AS PM2_5_Difference
FROM
  epa
JOIN
  openaq
ON
  epa.lat = openaq.lat
  AND epa.lon = openaq.lon
WHERE
  (epa.avg_pm25_1997 - openaq.avg_pm25_2020) > 0
ORDER BY
  PM2_5_Difference DESC
LIMIT 3;