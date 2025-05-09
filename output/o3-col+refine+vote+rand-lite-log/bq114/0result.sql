WITH epa_1990 AS (
  SELECT
    ROUND(latitude, 2)  AS lat2,
    ROUND(longitude, 2) AS lon2,
    ANY_VALUE(city_name) AS city_1990,
    AVG(arithmetic_mean) AS pm25_1990
  FROM `bigquery-public-data.epa_historical_air_quality.pm25_nonfrm_daily_summary`
  WHERE EXTRACT(YEAR FROM date_local) = 1990
    AND parameter_name   = 'Acceptable PM2.5 AQI & Speciation Mass'
    AND units_of_measure = 'Micrograms/cubic meter (LC)'
  GROUP BY lat2, lon2
),
aq_2020 AS (
  SELECT
    ROUND(latitude, 2)  AS lat2,
    ROUND(longitude, 2) AS lon2,
    ANY_VALUE(city)      AS city_2020,
    AVG(value)           AS pm25_2020
  FROM `bigquery-public-data.openaq.global_air_quality`
  WHERE pollutant = 'pm25'
    AND EXTRACT(YEAR FROM timestamp) = 2020
  GROUP BY lat2, lon2
)
SELECT
  COALESCE(aq.city_2020, epa.city_1990) AS city,
  epa.pm25_1990,
  aq.pm25_2020,
  ABS(aq.pm25_2020 - epa.pm25_1990)     AS pm25_difference
FROM epa_1990 epa
JOIN aq_2020  aq
USING (lat2, lon2)
ORDER BY pm25_difference DESC
LIMIT 3;