-- Three cities with the greatest absolute gap between
-- 1990 EPA PM2.5 (Acceptable PM2.5 AQI & Speciation Mass)
-- and 2020 OpenAQ PM2.5, matched on latitude/longitude
-- rounded to two decimals
WITH epa_1990 AS (
  SELECT
    ROUND(latitude , 2)                    AS lat2,
    ROUND(longitude, 2)                    AS lon2,
    AVG(arithmetic_mean)                   AS epa_pm25_1990,
    ANY_VALUE(city_name)                   AS epa_city
  FROM `bigquery-public-data.epa_historical_air_quality.pm25_nonfrm_daily_summary`
  WHERE EXTRACT(YEAR FROM date_local) = 1990
    AND parameter_name     = 'Acceptable PM2.5 AQI & Speciation Mass'
    AND units_of_measure   = 'Micrograms/cubic meter (LC)'
  GROUP BY lat2, lon2
),

openaq_2020 AS (
  SELECT
    ROUND(latitude , 2)                     AS lat2,
    ROUND(longitude, 2)                     AS lon2,
    AVG(value)                              AS openaq_pm25_2020,
    ANY_VALUE(city)                         AS oa_city
  FROM `bigquery-public-data.openaq.global_air_quality`
  WHERE pollutant = 'pm25'
    AND EXTRACT(YEAR FROM timestamp) = 2020
  GROUP BY lat2, lon2
),

joined AS (
  SELECT
    COALESCE(oa_city, epa_city)             AS city,
    e.lat2,
    e.lon2,
    e.epa_pm25_1990,
    o.openaq_pm25_2020,
    ABS(e.epa_pm25_1990 - o.openaq_pm25_2020) AS diff
  FROM epa_1990 e
  INNER JOIN openaq_2020 o
          ON e.lat2 = o.lat2
         AND e.lon2 = o.lon2
)

SELECT
  city,
  lat2  AS latitude_rounded,
  lon2  AS longitude_rounded,
  epa_pm25_1990,
  openaq_pm25_2020,
  diff  AS difference_pm25
FROM joined
ORDER BY diff DESC
LIMIT 3;