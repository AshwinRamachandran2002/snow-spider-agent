-- 3 cities with the greatest (2020 OpenAQ – 1990 EPA) PM2.5 difference
WITH epa_1990 AS (
  SELECT
    ROUND(latitude ,2)               AS lat2,
    ROUND(longitude,2)               AS lon2,
    AVG(arithmetic_mean)             AS epa_pm25_1990_avg,
    ANY_VALUE(city_name)             AS epa_city
  FROM `bigquery-public-data.epa_historical_air_quality.pm25_nonfrm_daily_summary`
  WHERE parameter_name   = 'Acceptable PM2.5 AQI & Speciation Mass'
    AND units_of_measure = 'Micrograms/cubic meter (LC)'
    AND EXTRACT(YEAR FROM date_local) = 1990
  GROUP BY lat2, lon2
),
openaq_2020 AS (
  SELECT
    ROUND(latitude ,2)               AS lat2,
    ROUND(longitude,2)               AS lon2,
    AVG(value)                       AS openaq_pm25_2020_avg,
    ANY_VALUE(city)                  AS openaq_city
  FROM `bigquery-public-data.openaq.global_air_quality`
  WHERE pollutant = 'pm25'
    AND EXTRACT(YEAR FROM timestamp) = 2020
  GROUP BY lat2, lon2
),
paired AS (
  SELECT
    e.lat2,
    e.lon2,
    COALESCE(o.openaq_city, e.epa_city)        AS city,
    e.epa_pm25_1990_avg,
    o.openaq_pm25_2020_avg,
    o.openaq_pm25_2020_avg - e.epa_pm25_1990_avg AS pm25_difference
  FROM epa_1990 e
  JOIN openaq_2020 o USING (lat2, lon2)
)
SELECT
  city,
  pm25_difference
FROM paired
ORDER BY pm25_difference DESC
LIMIT 3;