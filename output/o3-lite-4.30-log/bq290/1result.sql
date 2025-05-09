WITH country_day AS (
  SELECT
    g.date,
    s.country,
    AVG(g.max)  AS max_t,
    AVG(g.min)  AS min_t,
    AVG(g.temp) AS avg_t
  FROM `bigquery-public-data.noaa_gsod.gsod2023` AS g
  JOIN `bigquery-public-data.noaa_gsod.stations` AS s
    ON g.stn = s.usaf
   AND g.wban = s.wban
  WHERE s.country IN ('US', 'UK')
    AND g.date BETWEEN '2023-10-01' AND '2023-10-31'
    AND g.max  <> 9999.9
    AND g.min  <> 9999.9
    AND g.temp <> 9999.9
  GROUP BY g.date, s.country
),
pivot AS (
  SELECT
    date,
    MAX(IF(country = 'US', max_t, NULL)) AS us_max,
    MAX(IF(country = 'UK', max_t, NULL)) AS uk_max,
    MAX(IF(country = 'US', min_t, NULL)) AS us_min,
    MAX(IF(country = 'UK', min_t, NULL)) AS uk_min,
    MAX(IF(country = 'US', avg_t, NULL)) AS us_avg,
    MAX(IF(country = 'UK', avg_t, NULL)) AS uk_avg
  FROM country_day
  GROUP BY date
)
SELECT
  date,
  ROUND(us_max - uk_max, 4) AS max_temperature_diff,
  ROUND(us_min - uk_min, 4) AS min_temperature_diff,
  ROUND(us_avg - uk_avg, 4) AS avg_temperature_diff
FROM pivot
WHERE us_max IS NOT NULL
  AND uk_max IS NOT NULL
ORDER BY date;