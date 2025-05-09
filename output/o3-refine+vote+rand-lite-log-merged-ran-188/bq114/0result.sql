-- Top three cities with the greatest absolute change in PM2.5
WITH
/* 1990 EPA PM2.5 (daily, non‑FRM) aggregated to 2‑decimal lat/lon */
epa_1990 AS (
  SELECT
    ROUND(latitude ,2) AS lat2,
    ROUND(longitude,2) AS lon2,
    ANY_VALUE(city_name)            AS city_1990,          -- keep one name per location
    AVG(arithmetic_mean)            AS pm25_1990           -- μg/m³ LC, 1990 mean
  FROM `bigquery-public-data.epa_historical_air_quality.pm25_nonfrm_daily_summary`
  WHERE
        parameter_name   = 'Acceptable PM2.5 AQI & Speciation Mass'
    AND units_of_measure = 'Micrograms/cubic meter (LC)'
    AND EXTRACT(YEAR FROM date_local) = 1990
  GROUP BY lat2, lon2
),

/* 2020 OpenAQ PM2.5 hourly values aggregated to 2‑decimal lat/lon */
openaq_2020 AS (
  SELECT
    ROUND(latitude ,2) AS lat2,
    ROUND(longitude,2) AS lon2,
    ANY_VALUE(city)                AS city_2020,
    AVG(value)                     AS pm25_2020            -- μg/m³, 2020 mean
  FROM `bigquery-public-data.openaq.global_air_quality`
  WHERE
        pollutant = 'pm25'
    AND EXTRACT(YEAR FROM timestamp) = 2020
  GROUP BY lat2, lon2
)

/* Join the two years on rounded coordinates and rank by absolute difference */
SELECT
  COALESCE(e.city_1990, o.city_2020)            AS city,
  e.pm25_1990,
  o.pm25_2020,
  ABS(o.pm25_2020 - e.pm25_1990)                AS pm25_diff
FROM epa_1990 e
JOIN openaq_2020 o
USING (lat2, lon2)
ORDER BY pm25_diff DESC
LIMIT 3;