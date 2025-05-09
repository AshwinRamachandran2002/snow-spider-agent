-- Daily US‑vs‑UK temperature differences for October 2023
WITH valid_daily AS (
  SELECT
    -- build proper DATE value YYYY‑MM‑DD
    PARSE_DATE(
      '%Y%m%d',
      CONCAT(year, LPAD(mo, 2, '0'), LPAD(da, 2, '0'))
    )                           AS obs_date,
    s.country                   AS country,
    CAST(g.`max` AS FLOAT64)    AS max_t,
    CAST(g.`min` AS FLOAT64)    AS min_t,
    g.temp                      AS avg_t               -- daily mean temperature
  FROM  `bigquery-public-data.noaa_gsod.gsod2023`  AS g
  JOIN  `bigquery-public-data.noaa_gsod.stations`  AS s
        ON g.stn  = s.usaf
       AND g.wban = s.wban
  WHERE g.mo = '10'                        -- October
    AND s.country IN ('US','UK')           -- only USA & UK stations
    -- discard missing / placeholder temperature values
    AND g.`max` != 999.9
    AND g.`min` != 999.9
    AND g.temp  != 9999.9
),

country_day AS (
  -- aggregate for each country per calendar day
  SELECT
    obs_date,
    country,
    MAX(max_t)        AS country_max,      -- hottest station reading that day
    MIN(min_t)        AS country_min,      -- coldest station reading that day
    AVG(avg_t)        AS country_avg       -- mean of station daily‑means
  FROM valid_daily
  GROUP BY obs_date, country
),

pivot AS (
  -- pivot US and UK onto same row
  SELECT
    obs_date,
    MAX(CASE WHEN country = 'US' THEN country_max END) AS us_max,
    MAX(CASE WHEN country = 'UK' THEN country_max END) AS uk_max,
    MAX(CASE WHEN country = 'US' THEN country_min END) AS us_min,
    MAX(CASE WHEN country = 'UK' THEN country_min END) AS uk_min,
    MAX(CASE WHEN country = 'US' THEN country_avg END) AS us_avg,
    MAX(CASE WHEN country = 'UK' THEN country_avg END) AS uk_avg
  FROM country_day
  GROUP BY obs_date
)

SELECT
  obs_date                                       AS date,
  us_max - uk_max                                AS diff_max_temperature,
  us_min - uk_min                                AS diff_min_temperature,
  us_avg - uk_avg                                AS diff_avg_temperature
FROM pivot
WHERE us_max IS NOT NULL
  AND uk_max IS NOT NULL     -- ensure both countries reported that day
ORDER BY obs_date;