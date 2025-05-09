WITH epa_1990 AS (
  SELECT
    ROUND(latitude, 2)   AS lat2,
    ROUND(longitude, 2)  AS lon2,
    AVG(arithmetic_mean) AS epa_1990_pm25
  FROM `bigquery-public-data.epa_historical_air_quality.pm25_nonfrm_daily_summary`
  WHERE EXTRACT(YEAR FROM date_local) = 1990
    AND units_of_measure = 'Micrograms/cubic meter (LC)'
    AND parameter_name   = 'Acceptable PM2.5 AQI & Speciation Mass'
  GROUP BY lat2, lon2
),
openaq_2020 AS (
  SELECT
    ROUND(latitude, 2)  AS lat2,
    ROUND(longitude, 2) AS lon2,
    AVG(value)          AS openaq_2020_pm25,
    ANY_VALUE(city)     AS city
  FROM `bigquery-public-data.openaq.global_air_quality`
  WHERE pollutant = 'pm25'
    AND EXTRACT(YEAR FROM timestamp) = 2020
  GROUP BY lat2, lon2
)
SELECT
  o.city,
  o.openaq_2020_pm25,
  e.epa_1990_pm25,
  ABS(o.openaq_2020_pm25 - e.epa_1990_pm25) AS diff_pm25
FROM epa_1990 e
JOIN openaq_2020 o
USING (lat2, lon2)
ORDER BY diff_pm25 DESC
LIMIT 3;