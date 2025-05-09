-- 3 cities with the greatest absolute gap between 1990 EPA & 2020 OpenAQ PM2.5
WITH epa_1990 AS (
  SELECT
    ROUND(latitude, 2)  AS lat2 ,
    ROUND(longitude, 2) AS lon2 ,
    ANY_VALUE(city_name) AS city_1990 ,
    AVG(arithmetic_mean) AS pm25_1990
  FROM `bigquery-public-data.epa_historical_air_quality.pm25_nonfrm_daily_summary`
  WHERE parameter_name   = 'Acceptable PM2.5 AQI & Speciation Mass'
    AND units_of_measure = 'Micrograms/cubic meter (LC)'
    AND EXTRACT(YEAR FROM date_local) = 1990
  GROUP BY lat2 , lon2
),
openaq_2020 AS (
  SELECT
    ROUND(latitude, 2)  AS lat2 ,
    ROUND(longitude, 2) AS lon2 ,
    ANY_VALUE(city)     AS city_2020 ,
    AVG(value)          AS pm25_2020
  FROM `bigquery-public-data.openaq.global_air_quality`
  WHERE pollutant = 'pm25'
    AND EXTRACT(YEAR FROM timestamp) = 2020
  GROUP BY lat2 , lon2
)
SELECT
  COALESCE(o.city_2020 , e.city_1990) AS city ,
  ABS(e.pm25_1990 - o.pm25_2020)      AS pm25_difference
FROM epa_1990 e
JOIN openaq_2020 o
USING (lat2 , lon2)
ORDER BY pm25_difference DESC
LIMIT 3;