WITH epa_1990 AS (
  SELECT
    ROUND(latitude, 2)  AS lat2,
    ROUND(longitude, 2) AS lon2,
    AVG(arithmetic_mean) AS epa_pm25_1990
  FROM `bigquery-public-data.epa_historical_air_quality.pm25_nonfrm_daily_summary`
  WHERE EXTRACT(YEAR FROM `date_local`) = 1990
    AND parameter_name  = 'Acceptable PM2.5 AQI & Speciation Mass'
    AND units_of_measure = 'Micrograms/cubic meter (LC)'
  GROUP BY lat2, lon2
),
openaq_2020 AS (
  SELECT
    ROUND(latitude, 2)  AS lat2,
    ROUND(longitude, 2) AS lon2,
    ANY_VALUE(city)      AS city,          -- city name for result display
    AVG(value)           AS openaq_pm25_2020
  FROM `bigquery-public-data.openaq.global_air_quality`
  WHERE pollutant = 'pm25'
    AND EXTRACT(YEAR FROM `timestamp`) = 2020
  GROUP BY lat2, lon2
)
SELECT
  o.city,
  ABS(e.epa_pm25_1990 - o.openaq_pm25_2020) AS pm25_difference
FROM epa_1990 e
JOIN openaq_2020 o
USING (lat2, lon2)
ORDER BY pm25_difference DESC
LIMIT 3;