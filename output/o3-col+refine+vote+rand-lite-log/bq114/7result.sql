-- Three cities whose rounded-coordinate sites show the biggest absolute gap
-- between average 1990 EPA PM2.5 and average 2020 OpenAQ PM2.5
WITH epa_1990 AS (          -- aggregate EPA sites for 1990
  SELECT
    ROUND(latitude ,2)                    AS lat2,
    ROUND(longitude,2)                    AS lon2,
    ANY_VALUE(city_name)                  AS city,
    AVG(arithmetic_mean)                  AS epa_1990_pm25
  FROM `bigquery-public-data.epa_historical_air_quality.pm25_nonfrm_daily_summary`
  WHERE EXTRACT(YEAR FROM date_local) = 1990
    AND parameter_name   = 'Acceptable PM2.5 AQI & Speciation Mass'
    AND units_of_measure = 'Micrograms/cubic meter (LC)'
  GROUP BY lat2, lon2
),
openaq_2020 AS (            -- aggregate OpenAQ sites for 2020
  SELECT
    ROUND(latitude ,2)                    AS lat2,
    ROUND(longitude,2)                    AS lon2,
    ANY_VALUE(city)                       AS city,
    AVG(value)                            AS openaq_2020_pm25
  FROM `bigquery-public-data.openaq.global_air_quality`
  WHERE pollutant = 'pm25'
    AND EXTRACT(YEAR FROM timestamp) = 2020
  GROUP BY lat2, lon2
)
SELECT
  COALESCE(op.city, ep.city)              AS city,
  ABS(op.openaq_2020_pm25 - ep.epa_1990_pm25) AS pm25_difference,
  ep.epa_1990_pm25,
  op.openaq_2020_pm25
FROM epa_1990 AS ep
JOIN openaq_2020 AS op
  USING (lat2, lon2)
ORDER BY pm25_difference DESC
LIMIT 3;