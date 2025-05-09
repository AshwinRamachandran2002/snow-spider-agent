-- 3 cities with the greatest change between 1990 EPA PM2.5 
-- and 2020 OpenAQ PM2.5 (lat/lon rounded to two decimals)

WITH epa_1990 AS (
  SELECT
    ROUND(latitude ,2) AS lat2,
    ROUND(longitude,2) AS lon2,
    AVG(arithmetic_mean)          AS epa_pm25_1990     -- average 1990 PM2.5 (µg/m³ LC)
  FROM `bigquery-public-data.epa_historical_air_quality.pm25_nonfrm_daily_summary`
  WHERE EXTRACT(YEAR FROM date_local) = 1990
    AND units_of_measure = 'Micrograms/cubic meter (LC)'
    AND parameter_name    = 'Acceptable PM2.5 AQI & Speciation Mass'
  GROUP BY lat2, lon2
),

openaq_2020 AS (
  SELECT
    ROUND(latitude ,2) AS lat2,
    ROUND(longitude,2) AS lon2,
    AVG(value)                     AS openaq_pm25_2020,  -- average 2020 PM2.5
    ANY_VALUE(city)                AS city               -- representative city name
  FROM `bigquery-public-data.openaq.global_air_quality`
  WHERE pollutant = 'pm25'
    AND EXTRACT(YEAR FROM timestamp) = 2020
  GROUP BY lat2, lon2
),

joined AS (
  SELECT
    o.city,
    o.lat2,
    o.lon2,
    e.epa_pm25_1990,
    o.openaq_pm25_2020,
    ABS(o.openaq_pm25_2020 - e.epa_pm25_1990) AS diff
  FROM openaq_2020  o
  JOIN epa_1990     e USING (lat2, lon2)
)

SELECT
  city,
  diff
FROM joined
ORDER BY diff DESC
LIMIT 3;