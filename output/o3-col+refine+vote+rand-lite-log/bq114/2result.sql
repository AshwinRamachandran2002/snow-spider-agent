WITH epa AS (
  SELECT
    ROUND(latitude , 2)  AS lat2,
    ROUND(longitude, 2)  AS lon2,
    AVG(arithmetic_mean) AS epa_pm25_1990,
    ANY_VALUE(city_name) AS epa_city
  FROM `bigquery-public-data.epa_historical_air_quality.pm25_nonfrm_daily_summary`
  WHERE EXTRACT(YEAR FROM date_local) = 1990
    AND units_of_measure = 'Micrograms/cubic meter (LC)'
    AND parameter_name   = 'Acceptable PM2.5 AQI & Speciation Mass'
  GROUP BY lat2, lon2
),
aq AS (
  SELECT
    ROUND(latitude , 2)  AS lat2,
    ROUND(longitude, 2)  AS lon2,
    AVG(value)           AS aq_pm25_2020,
    ANY_VALUE(city)      AS aq_city
  FROM `bigquery-public-data.openaq.global_air_quality`
  WHERE pollutant = 'pm25'
    AND EXTRACT(YEAR FROM `timestamp`) = 2020
  GROUP BY lat2, lon2
)
SELECT
  COALESCE(epa_city, aq_city)               AS city,
  epa_pm25_1990,
  aq_pm25_2020,
  ABS(epa_pm25_1990 - aq_pm25_2020)         AS pm25_difference
FROM epa
JOIN aq USING (lat2, lon2)
ORDER BY pm25_difference DESC
LIMIT 3;