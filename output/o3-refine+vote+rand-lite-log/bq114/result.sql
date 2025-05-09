WITH epa_1990 AS (
  SELECT
    ROUND(latitude, 2) AS lat2,
    ROUND(longitude, 2) AS lon2,
    AVG(arithmetic_mean) AS epa_pm25,
    ANY_VALUE(city_name) AS city_epa
  FROM `bigquery-public-data.epa_historical_air_quality.pm25_nonfrm_daily_summary`
  WHERE
    EXTRACT(YEAR FROM date_local) = 1990
    AND units_of_measure = 'Micrograms/cubic meter (LC)'
    AND parameter_name = 'Acceptable PM2.5 AQI & Speciation Mass'
  GROUP BY
    lat2, lon2
),
openaq_2020 AS (
  SELECT
    ROUND(latitude, 2) AS lat2,
    ROUND(longitude, 2) AS lon2,
    AVG(value) AS openaq_pm25,
    ANY_VALUE(city) AS city_open
  FROM `bigquery-public-data.openaq.global_air_quality`
  WHERE
    pollutant = 'pm25'
    AND EXTRACT(YEAR FROM `timestamp`) = 2020
  GROUP BY
    lat2, lon2
),
joined AS (
  SELECT
    COALESCE(o.city_open, e.city_epa) AS city,
    e.epa_pm25,
    o.openaq_pm25,
    ABS(o.openaq_pm25 - e.epa_pm25) AS diff
  FROM
    epa_1990 e
  JOIN
    openaq_2020 o
  ON
    e.lat2 = o.lat2
    AND e.lon2 = o.lon2
)
SELECT
  city,
  diff
FROM
  joined
ORDER BY
  diff DESC
LIMIT 3;