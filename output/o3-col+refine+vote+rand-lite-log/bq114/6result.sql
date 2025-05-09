/*  Cities with the three largest 1990-vs-2020 PM2.5 differences  */
WITH epa_1990 AS (
  SELECT
    ROUND(latitude, 2)          AS lat2,
    ROUND(longitude, 2)         AS lon2,
    ANY_VALUE(city_name)        AS epa_city,
    AVG(arithmetic_mean)        AS epa_pm25_1990
  FROM `bigquery-public-data.epa_historical_air_quality.pm25_nonfrm_daily_summary`
  WHERE EXTRACT(YEAR FROM date_local) = 1990
    AND units_of_measure = 'Micrograms/cubic meter (LC)'
    AND parameter_name   = 'Acceptable PM2.5 AQI & Speciation Mass'
  GROUP BY lat2, lon2
),
openaq_2020 AS (
  SELECT
    ROUND(latitude, 2)          AS lat2,
    ROUND(longitude, 2)         AS lon2,
    ANY_VALUE(city)             AS openaq_city,
    AVG(value)                  AS openaq_pm25_2020
  FROM `bigquery-public-data.openaq.global_air_quality`
  WHERE pollutant = 'pm25'
    AND EXTRACT(YEAR FROM timestamp) = 2020
  GROUP BY lat2, lon2
),
paired AS (
  SELECT
    e.lat2,
    e.lon2,
    COALESCE(e.epa_city, o.openaq_city) AS city,
    e.epa_pm25_1990,
    o.openaq_pm25_2020,
    ABS(o.openaq_pm25_2020 - e.epa_pm25_1990) AS pm25_difference
  FROM epa_1990 e
  JOIN openaq_2020 o
  USING (lat2, lon2)
)
SELECT
  city,
  pm25_difference,
  epa_pm25_1990,
  openaq_pm25_2020
FROM paired
ORDER BY pm25_difference DESC
LIMIT 3;