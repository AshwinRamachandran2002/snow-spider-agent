WITH
-- 1.  Daily statistics for U.S. stations in October-2023
us AS (
  SELECT
    DATE(CONCAT(year, '-', mo, '-', da))                                            AS obs_date,
    AVG(temp)                                                                      AS avg_us,
    MAX(max)                                                                       AS max_us,
    MIN(min)                                                                       AS min_us
  FROM `bigquery-public-data.noaa_gsod.gsod2023`  g
  JOIN `bigquery-public-data.noaa_gsod.stations` s
        ON g.stn = s.usaf AND g.wban = s.wban
  WHERE s.country = 'US'
    AND mo = '10'                                         -- October
    AND temp < 9000 AND max < 9000 AND min < 9000         -- exclude “9999.9” missing values
  GROUP BY obs_date
),

-- 2.  Daily statistics for U.K. stations in October-2023
uk AS (
  SELECT
    DATE(CONCAT(year, '-', mo, '-', da))                                            AS obs_date,
    AVG(temp)                                                                      AS avg_uk,
    MAX(max)                                                                       AS max_uk,
    MIN(min)                                                                       AS min_uk
  FROM `bigquery-public-data.noaa_gsod.gsod2023`  g
  JOIN `bigquery-public-data.noaa_gsod.stations` s
        ON g.stn = s.usaf AND g.wban = s.wban
  WHERE s.country = 'UK'
    AND mo = '10'
    AND temp < 9000 AND max < 9000 AND min < 9000
  GROUP BY obs_date
)

-- 3.  Temperature differences (US − UK) for each October-2023 day
SELECT
  u.obs_date                                                             AS observation_date,
  ROUND(u.max_us - k.max_uk, 4)                                          AS max_temp_difference,
  ROUND(u.min_us - k.min_uk, 4)                                          AS min_temp_difference,
  ROUND(u.avg_us - k.avg_uk, 4)                                          AS avg_temp_difference
FROM us u
JOIN uk k
  ON u.obs_date = k.obs_date
ORDER BY observation_date;