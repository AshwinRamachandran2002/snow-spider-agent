WITH epa_data AS (
  SELECT
    ROUND(latitude, 2) AS lat,
    ROUND(longitude, 2) AS lon,
    AVG(arithmetic_mean) AS avg_pm25_1990,
    ANY_VALUE(city_name) AS City_1990
  FROM
    `bigquery-public-data.epa_historical_air_quality.air_quality_annual_summary`
  WHERE
    parameter_name = 'Acceptable PM2.5 AQI & Speciation Mass'
    AND units_of_measure = 'Micrograms/cubic meter (LC)'
    AND year = 1990
  GROUP BY
    lat, lon
),
openaq_data AS (
  SELECT
    ROUND(latitude, 2) AS lat,
    ROUND(longitude, 2) AS lon,
    AVG(value) AS avg_pm25_2020,
    ANY_VALUE(city) AS City_2020
  FROM
    `bigquery-public-data.openaq.global_air_quality`
  WHERE
    pollutant = 'pm25'
    AND EXTRACT(YEAR FROM timestamp) = 2020
    AND latitude IS NOT NULL
    AND longitude IS NOT NULL
    AND latitude != 1.0
  GROUP BY
    lat, lon
)
SELECT
  COALESCE(openaq_data.City_2020, epa_data.City_1990) AS City,
  ROUND(epa_data.avg_pm25_1990 - openaq_data.avg_pm25_2020, 4) AS PM2_5_Difference
FROM
  epa_data
JOIN
  openaq_data
ON
  epa_data.lat = openaq_data.lat
  AND epa_data.lon = openaq_data.lon
WHERE
  (epa_data.avg_pm25_1990 - openaq_data.avg_pm25_2020) > 0
ORDER BY
  PM2_5_Difference DESC
LIMIT
  3;