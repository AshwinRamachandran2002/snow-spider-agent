-- Daily difference (US – UK) in maximum, minimum and average temperatures
-- for every day of October 2023.  Missing / sentinel values (e.g. 9999.9 or
-- 9999.99) are excluded.

WITH valid_rows AS (
  SELECT
    DATE(CAST(g.year AS INT64),
         CAST(g.mo   AS INT64),
         CAST(g.da   AS INT64))              AS obs_date,
    s.country                                 AS country_code,
    g.temp                                    AS mean_temp,
    g.max                                     AS max_temp,
    g.min                                     AS min_temp
  FROM `bigquery-public-data.noaa_gsod.gsod2023` AS g
  JOIN `bigquery-public-data.noaa_gsod.stations` AS s
    ON g.stn  = s.usaf
   AND g.wban = s.wban
  WHERE g.year = '2023'
    AND g.mo   = '10'                 -- October only
    AND s.country IN ('US','UK')      -- keep United States and United Kingdom
    -- discard rows with missing / invalid temperature values
    AND g.temp NOT IN (9999.9, 9999.99)
    AND g.max  NOT IN (9999.9, 9999.99)
    AND g.min  NOT IN (9999.9, 9999.99)
),

country_day_stats AS (
  SELECT
    obs_date,
    country_code,
    AVG(mean_temp) AS avg_mean_temp,
    AVG(max_temp)  AS avg_max_temp,
    AVG(min_temp)  AS avg_min_temp
  FROM valid_rows
  GROUP BY obs_date, country_code
),

pivoted AS (
  SELECT
    obs_date,
    MAX(CASE WHEN country_code = 'US' THEN avg_max_temp  END) AS us_max,
    MAX(CASE WHEN country_code = 'UK' THEN avg_max_temp  END) AS uk_max,
    MAX(CASE WHEN country_code = 'US' THEN avg_min_temp  END) AS us_min,
    MAX(CASE WHEN country_code = 'UK' THEN avg_min_temp  END) AS uk_min,
    MAX(CASE WHEN country_code = 'US' THEN avg_mean_temp END) AS us_avg,
    MAX(CASE WHEN country_code = 'UK' THEN avg_mean_temp END) AS uk_avg
  FROM country_day_stats
  GROUP BY obs_date
)

SELECT
  obs_date,
  us_max - uk_max  AS diff_max_temperature,
  us_min - uk_min  AS diff_min_temperature,
  us_avg - uk_avg  AS diff_avg_temperature
FROM pivoted
WHERE us_max IS NOT NULL AND uk_max IS NOT NULL   -- keep days with data for both countries
ORDER BY obs_date;