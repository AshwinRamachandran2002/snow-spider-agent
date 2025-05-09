/* Which three cities show the biggest change between
   their 1990 EPA PM2.5 levels and their 2020 OpenAQ PM2.5 levels?
*/
WITH epa_1990 AS (
  SELECT
    ROUND(latitude ,2)            AS lat_round,
    ROUND(longitude,2)            AS lon_round,
    ANY_VALUE(city_name)          AS epa_city,
    AVG(arithmetic_mean)          AS pm25_1990
  FROM `bigquery-public-data.epa_historical_air_quality.pm25_nonfrm_daily_summary`
  WHERE parameter_name   = 'Acceptable PM2.5 AQI & Speciation Mass'
    AND units_of_measure = 'Micrograms/cubic meter (LC)'
    AND EXTRACT(YEAR FROM date_local) = 1990
  GROUP BY lat_round, lon_round
),
openaq_2020 AS (
  SELECT
    ROUND(latitude ,2) AS lat_round,
    ROUND(longitude,2) AS lon_round,
    ANY_VALUE(city)    AS openaq_city,
    AVG(value)         AS pm25_2020
  FROM `bigquery-public-data.openaq.global_air_quality`
  WHERE pollutant = 'pm25'
    AND EXTRACT(YEAR FROM `timestamp`) = 2020
  GROUP BY lat_round, lon_round
),
joined AS (
  SELECT
    COALESCE(e.epa_city, o.openaq_city)     AS city,
    e.pm25_1990,
    o.pm25_2020,
    ABS(o.pm25_2020 - e.pm25_1990)          AS diff_pm25
  FROM epa_1990 e
  JOIN openaq_2020 o
    USING (lat_round, lon_round)
)
SELECT
  city,
  pm25_1990,
  pm25_2020,
  diff_pm25
FROM joined
ORDER BY diff_pm25 DESC
LIMIT 3;