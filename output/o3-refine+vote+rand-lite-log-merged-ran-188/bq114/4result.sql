WITH epa_1990 AS (   -- 1990 EPA PM2.5  (daily, LC units)
  SELECT
    ROUND(latitude ,2) AS lat2,
    ROUND(longitude,2) AS lon2,
    AVG(arithmetic_mean)            AS epa_pm25_1990
  FROM  `bigquery-public-data.epa_historical_air_quality.pm25_nonfrm_daily_summary`
  WHERE parameter_name   = 'Acceptable PM2.5 AQI & Speciation Mass'
    AND units_of_measure = 'Micrograms/cubic meter (LC)'
    AND EXTRACT(YEAR FROM date_local) = 1990
  GROUP BY lat2, lon2
),
openaq_2020 AS (      -- 2020 OpenAQ PM2.5
  SELECT
    ROUND(latitude ,2) AS lat2,
    ROUND(longitude,2) AS lon2,
    ANY_VALUE(city)                  AS city,
    AVG(value)                       AS openaq_pm25_2020
  FROM `bigquery-public-data.openaq.global_air_quality`
  WHERE pollutant = 'pm25'
    AND EXTRACT(YEAR FROM timestamp) = 2020
  GROUP BY lat2, lon2
),
diffs AS (            -- join on rounded coordinates
  SELECT
    o.city,
    ABS(o.openaq_pm25_2020 - e.epa_pm25_1990) AS pm25_difference
  FROM openaq_2020 o
  JOIN epa_1990  e
    ON  o.lat2 = e.lat2
    AND o.lon2 = e.lon2
)
SELECT
  city,
  pm25_difference
FROM diffs
ORDER BY pm25_difference DESC
LIMIT 3;