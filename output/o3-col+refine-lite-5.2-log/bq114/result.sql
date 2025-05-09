-- 3 cities whose locations show the greatest change in average PM2.5
-- between 1990 (EPA) and 2020 (OpenAQ), matched on lat/lon rounded to 0.01°
WITH
/* 1990 U S‑EPA daily averages */
epa_1990 AS (
  SELECT
    ROUND(latitude ,2)       AS lat2,
    ROUND(longitude,2)       AS lon2,
    AVG(arithmetic_mean)     AS pm25_1990,
    ANY_VALUE(city_name)     AS city
  FROM `bigquery-public-data.epa_historical_air_quality.pm25_nonfrm_daily_summary`
  WHERE parameter_name   = 'Acceptable PM2.5 AQI & Speciation Mass'
    AND units_of_measure = 'Micrograms/cubic meter (LC)'
    AND date_local BETWEEN '1990-01-01' AND '1990-12-31'
  GROUP BY lat2, lon2
),

/* 2020 OpenAQ hourly averages */
openaq_2020 AS (
  SELECT
    ROUND(latitude ,2)   AS lat2,
    ROUND(longitude,2)   AS lon2,
    AVG(value)           AS pm25_2020
  FROM `bigquery-public-data.openaq.global_air_quality`
  WHERE pollutant = 'pm25'
    AND EXTRACT(YEAR FROM timestamp) = 2020
  GROUP BY lat2, lon2
)

/* join on rounded coordinates and rank by absolute difference */
SELECT
  e.city                                        AS city,
  ROUND(e.pm25_1990 ,2)                         AS pm25_1990,
  ROUND(o.pm25_2020 ,2)                         AS pm25_2020,
  ROUND(ABS(o.pm25_2020 - e.pm25_1990),2)       AS difference
FROM epa_1990 e
JOIN openaq_2020 o USING (lat2, lon2)
ORDER BY difference DESC
LIMIT 3;