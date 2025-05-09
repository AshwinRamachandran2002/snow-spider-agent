WITH valid_obs AS (
  SELECT
    g.date,
    s.country,
    g.temp,
    g.max,
    g.min
  FROM `bigquery-public-data.noaa_gsod.gsod2023` AS g
  JOIN `bigquery-public-data.noaa_gsod.stations` AS s
    ON s.usaf = g.stn
   AND s.wban = g.wban
  WHERE g.date BETWEEN '2023-10-01' AND '2023-10-31'
    AND s.country IN ('US', 'UK')
    AND g.temp < 9999.9
    AND g.max  < 9999.9
    AND g.min  < 9999.9
),
daily_country AS (
  SELECT
    date,
    country,
    AVG(temp) AS avg_temp,
    AVG(max)  AS avg_max,
    AVG(min)  AS avg_min
  FROM valid_obs
  GROUP BY date, country
),
pivot AS (
  SELECT
    date,
    MAX(CASE WHEN country = 'US' THEN avg_temp END) AS us_avg_temp,
    MAX(CASE WHEN country = 'UK' THEN avg_temp END) AS uk_avg_temp,
    MAX(CASE WHEN country = 'US' THEN avg_max  END) AS us_avg_max,
    MAX(CASE WHEN country = 'UK' THEN avg_max  END) AS uk_avg_max,
    MAX(CASE WHEN country = 'US' THEN avg_min  END) AS us_avg_min,
    MAX(CASE WHEN country = 'UK' THEN avg_min  END) AS uk_avg_min
  FROM daily_country
  GROUP BY date
)
SELECT
  date,
  ROUND(us_avg_max - uk_avg_max, 4) AS max_temperature_diff,
  ROUND(us_avg_min - uk_avg_min, 4) AS min_temperature_diff,
  ROUND(us_avg_temp - uk_avg_temp, 4) AS avg_temperature_diff
FROM pivot
WHERE us_avg_temp IS NOT NULL AND uk_avg_temp IS NOT NULL
ORDER BY date;