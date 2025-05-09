WITH epa_1990 AS (
  SELECT
    ROUND(latitude, 2)                     AS lat2,
    ROUND(longitude, 2)                    AS lon2,
    AVG(arithmetic_mean)                   AS epa_pm25_1990,
    ANY_VALUE(city_name)                   AS epa_city
  FROM `bigquery-public-data.epa_historical_air_quality.pm25_nonfrm_daily_summary`
  WHERE EXTRACT(YEAR FROM `date_local`) = 1990
    AND parameter_name = 'Acceptable PM2.5 AQI & Speciation Mass'
    AND units_of_measure = 'Micrograms/cubic meter (LC)'
  GROUP BY lat2, lon2
),

openaq_2020 AS (
  SELECT
    ROUND(latitude, 2)          AS lat2,
    ROUND(longitude, 2)         AS lon2,
    AVG(value)                  AS open_pm25_2020,
    ANY_VALUE(city)             AS open_city
  FROM `bigquery-public-data.openaq.global_air_quality`
  WHERE pollutant = 'pm25'
    AND EXTRACT(YEAR FROM `timestamp`) = 2020
  GROUP BY lat2, lon2
),

diffs AS (
  SELECT
    COALESCE(o.open_city, e.epa_city)      AS city,
    ABS(o.open_pm25_2020 - e.epa_pm25_1990) AS diff_pm25
  FROM epa_1990 e
  JOIN openaq_2020 o
  ON  e.lat2 = o.lat2
  AND e.lon2 = o.lon2
)

SELECT city,
       diff_pm25 AS difference_pm25_ug_m3
FROM diffs
ORDER BY diff_pm25 DESC
LIMIT 3;