-- Three cities whose locations show the largest change in average PM2.5
-- between EPA (1990) and OpenAQ (2020), matched on lat/lon rounded to 0.01°
WITH
/* 1990 EPA daily-mean PM2.5 (non-FRM) aggregated to site */
epa_1990 AS (
  SELECT
    ROUND(latitude ,2)                 AS lat2,
    ROUND(longitude,2)                 AS lon2,
    ANY_VALUE(city_name)               AS city_1990,
    AVG(arithmetic_mean)               AS pm25_1990
  FROM `bigquery-public-data.epa_historical_air_quality.pm25_nonfrm_daily_summary`
  WHERE EXTRACT(YEAR FROM date_local) = 1990
    AND units_of_measure = 'Micrograms/cubic meter (LC)'
    AND parameter_name   = 'Acceptable PM2.5 AQI & Speciation Mass'
  GROUP BY lat2, lon2
),

/* 2020 OpenAQ PM2.5 aggregated to the same spatial resolution */
openaq_2020 AS (
  SELECT
    ROUND(latitude ,2)               AS lat2,
    ROUND(longitude,2)               AS lon2,
    ANY_VALUE(city)                  AS city_2020,
    AVG(value)                       AS pm25_2020
  FROM `bigquery-public-data.openaq.global_air_quality`
  WHERE pollutant = 'pm25'
    AND EXTRACT(YEAR FROM timestamp) = 2020
  GROUP BY lat2, lon2
)

/* Compare the two years and pick the largest absolute differences */
SELECT
  COALESCE(o.city_2020, e.city_1990)      AS city,
  e.pm25_1990,
  o.pm25_2020,
  ABS(o.pm25_2020 - e.pm25_1990)          AS pm25_difference
FROM epa_1990 e
JOIN openaq_2020 o USING (lat2, lon2)
ORDER BY pm25_difference DESC
LIMIT 3;