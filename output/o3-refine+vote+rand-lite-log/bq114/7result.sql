WITH
/* 1.  EPA 1990 PM2.5 (Acceptable PM2.5 AQI & Speciation Mass) */
epa_1990 AS (
  SELECT
    ROUND(latitude, 2)            AS lat_2dec,
    ROUND(longitude, 2)           AS lon_2dec,
    AVG(arithmetic_mean)          AS epa_pm25_1990,
    ANY_VALUE(COALESCE(city_name, local_site_name, address)) AS epa_city
  FROM
    `bigquery-public-data.epa_historical_air_quality.pm25_nonfrm_daily_summary`
  WHERE
        parameter_name = 'Acceptable PM2.5 AQI & Speciation Mass'
    AND units_of_measure = 'Micrograms/cubic meter (LC)'
    AND EXTRACT(YEAR FROM date_local) = 1990
    AND latitude IS NOT NULL
    AND longitude IS NOT NULL
  GROUP BY
    lat_2dec, lon_2dec
),

/* 2.  OpenAQ 2020 PM2.5 */
openaq_2020 AS (
  SELECT
    ROUND(latitude, 2)            AS lat_2dec,
    ROUND(longitude, 2)           AS lon_2dec,
    AVG(value)                    AS openaq_pm25_2020,
    ANY_VALUE(city)               AS openaq_city
  FROM
    `bigquery-public-data.openaq.global_air_quality`
  WHERE
        pollutant = 'pm25'
    AND EXTRACT(YEAR FROM timestamp) = 2020
    AND latitude  BETWEEN -90 AND 90      -- basic sanity‑check
    AND longitude BETWEEN -180 AND 180
  GROUP BY
    lat_2dec, lon_2dec
)

/* 3.  Join on rounded coordinates, compute absolute difference, pick top 3 */
SELECT
  COALESCE(o.openaq_city, e.epa_city)     AS city,
  ABS(e.epa_pm25_1990 - o.openaq_pm25_2020) AS pm25_difference
FROM
  epa_1990 AS e
JOIN
  openaq_2020 AS o
USING (lat_2dec, lon_2dec)
ORDER BY
  pm25_difference DESC
LIMIT 3;