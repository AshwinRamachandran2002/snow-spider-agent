/*  Daily U.S. – U.K. temperature differences for Oct-2023  */
WITH base AS (
  SELECT
    DATE(CONCAT(g.year,'-',g.mo,'-',g.da))      AS day,
    g.max                                       AS max_F,
    g.min                                       AS min_F,
    g.temp                                      AS mean_F,
    s.country,
    s.lat,
    s.lon
  FROM `bigquery-public-data.noaa_gsod.gsod2023` AS g
  JOIN `bigquery-public-data.noaa_gsod.stations` AS s
    ON g.stn = s.usaf
  WHERE g.mo = '10'
    -- discard missing / invalid temperature values
    AND g.max  < 9000
    AND g.min  < 9000
    AND g.temp < 9000
),
us AS (
  SELECT
    day,
    MAX(max_F)            AS us_max,
    MIN(min_F)            AS us_min,
    AVG(mean_F)           AS us_avg
  FROM base
  WHERE country = 'US'
  GROUP BY day
),
uk AS (
  SELECT
    day,
    MAX(max_F)            AS uk_max,
    MIN(min_F)            AS uk_min,
    AVG(mean_F)           AS uk_avg
  FROM base
  -- geographic bounds covering the United Kingdom
  WHERE lat BETWEEN 49 AND 61
    AND lon BETWEEN -11 AND   2
  GROUP BY day
)
SELECT
  us.day,
  (us.us_max - uk.uk_max)  AS diff_max_F,   -- U.S. − U.K. daily maximum (°F)
  (us.us_min - uk.uk_min)  AS diff_min_F,   -- U.S. − U.K. daily minimum (°F)
  (us.us_avg - uk.uk_avg)  AS diff_avg_F    -- U.S. − U.K. daily mean    (°F)
FROM us
JOIN uk USING (day)
ORDER BY day;