-- Daily (US-UK) temperature differences for October 2023
WITH valid_rows AS (
  -- keep only records from Oct-2023 that have real (≠ 9999.9) temps
  SELECT
    DATE(SAFE_CAST(g.year AS INT64),
         SAFE_CAST(g.mo   AS INT64),
         SAFE_CAST(g.da   AS INT64))            AS day,
    s.country,          -- US or UK
    g.max   AS max_temp,
    g.min   AS min_temp,
    g.temp  AS avg_temp
  FROM `bigquery-public-data.noaa_gsod.gsod2023`  AS g
  JOIN `bigquery-public-data.noaa_gsod.stations`  AS s
    ON g.stn = s.usaf AND g.wban = s.wban
  WHERE g.year = '2023'
    AND g.mo   = '10'                     -- October
    AND s.country IN ('US','UK')
    AND g.max  NOT IN (9999.9)
    AND g.min  NOT IN (9999.9)
    AND g.temp NOT IN (9999.9)
),
country_day_stats AS (
  -- aggregate per country & day
  SELECT
    day,
    country,
    MAX(max_temp)            AS max_temp,
    MIN(min_temp)            AS min_temp,
    AVG(avg_temp)            AS avg_temp
  FROM valid_rows
  GROUP BY day, country
),
us AS (
  SELECT day, max_temp AS us_max, min_temp AS us_min, avg_temp AS us_avg
  FROM   country_day_stats
  WHERE  country = 'US'
),
uk AS (
  SELECT day, max_temp AS uk_max, min_temp AS uk_min, avg_temp AS uk_avg
  FROM   country_day_stats
  WHERE  country = 'UK'
)
SELECT
  u.day,
  u.us_max - k.uk_max AS diff_max,  -- US minus UK
  u.us_min - k.uk_min AS diff_min,
  u.us_avg - k.uk_avg AS diff_avg
FROM us AS u
JOIN uk AS k USING(day)
ORDER BY u.day;