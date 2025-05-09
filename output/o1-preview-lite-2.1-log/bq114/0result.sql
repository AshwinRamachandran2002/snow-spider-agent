WITH epa_pm10 AS (
  SELECT
    ROUND(latitude, 2) AS latitude_rounded,
    ROUND(longitude, 2) AS longitude_rounded,
    AVG(arithmetic_mean) AS avg_pm10_epa,
    ANY_VALUE(city_name) AS city_name
  FROM
    `bigquery-public-data.epa_historical_air_quality.pm10_daily_summary`
  WHERE
    EXTRACT(YEAR FROM date_local) = 1990
    AND LOWER(parameter_name) LIKE '%pm10%'
  GROUP BY
    latitude_rounded,
    longitude_rounded
),
openaq_pm10 AS (
  SELECT
    ROUND(latitude, 2) AS latitude_rounded,
    ROUND(longitude, 2) AS longitude_rounded,
    AVG(value) AS avg_pm10_openaq,
    ANY_VALUE(city) AS city
  FROM
    `bigquery-public-data.openaq.global_air_quality`
  WHERE
    EXTRACT(YEAR FROM timestamp) = 2020
    AND LOWER(pollutant) = 'pm10'
  GROUP BY
    latitude_rounded,
    longitude_rounded
),
joined_data AS (
  SELECT
    COALESCE(epa.city_name, openaq.city) AS City,
    epa.avg_pm10_epa,
    openaq.avg_pm10_openaq,
    ABS(openaq.avg_pm10_openaq - epa.avg_pm10_epa) AS Difference_in_PM10
  FROM
    epa_pm10 AS epa
  JOIN
    openaq_pm10 AS openaq
  ON
    epa.latitude_rounded = openaq.latitude_rounded
    AND epa.longitude_rounded = openaq.longitude_rounded
)
SELECT
  City,
  Difference_in_PM10
FROM
  joined_data
ORDER BY
  Difference_in_PM10 DESC
LIMIT
  3;