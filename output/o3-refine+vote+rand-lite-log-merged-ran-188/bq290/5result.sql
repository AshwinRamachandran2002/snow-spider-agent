/* Daily U.S.-vs-U.K. temperature differences (°F) for October-2023 */
WITH
-- U.S. aggregates ------------------------------------------------------------
us_daily AS (
  SELECT
    DATE(2023, 10, CAST(g.da AS INT64))        AS obs_date,
    MAX(g.max)                                AS us_max,
    MIN(g.min)                                AS us_min,
    AVG(g.temp)                               AS us_avg
  FROM `bigquery-public-data.noaa_gsod.gsod2023` AS g
  JOIN `bigquery-public-data.noaa_gsod.stations` AS s
    ON g.stn = s.usaf AND g.wban = s.wban
  WHERE g.year = '2023'
    AND g.mo   = '10'
    AND s.country = 'US'
    -- discard missing / invalid values
    AND g.temp < 9999
    AND g.max  <  999
    AND g.min  <  999
  GROUP BY obs_date
),

-- U.K. aggregates ------------------------------------------------------------
uk_daily AS (
  SELECT
    DATE(2023, 10, CAST(g.da AS INT64))        AS obs_date,
    MAX(g.max)                                AS uk_max,
    MIN(g.min)                                AS uk_min,
    AVG(g.temp)                               AS uk_avg
  FROM `bigquery-public-data.noaa_gsod.gsod2023` AS g
  JOIN `bigquery-public-data.noaa_gsod.stations` AS s
    ON g.stn = s.usaf AND g.wban = s.wban
  WHERE g.year = '2023'
    AND g.mo   = '10'
    AND s.country = 'UK'
    -- discard missing / invalid values
    AND g.temp < 9999
    AND g.max  <  999
    AND g.min  <  999
  GROUP BY obs_date
)

-- Final daily differences ----------------------------------------------------
SELECT
  u.obs_date,
  ROUND(u.us_max - k.uk_max, 4) AS diff_max_temp_f,
  ROUND(u.us_min - k.uk_min, 4) AS diff_min_temp_f,
  ROUND(u.us_avg - k.uk_avg, 4) AS diff_avg_temp_f
FROM us_daily AS u
JOIN uk_daily AS k
  ON u.obs_date = k.obs_date
ORDER BY u.obs_date;