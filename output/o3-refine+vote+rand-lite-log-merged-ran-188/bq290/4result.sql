-- Daily US-vs-UK temperature differences for October 2023
WITH valid_obs AS (
  SELECT
    DATE(CAST(g.year AS INT64), CAST(g.mo AS INT64), CAST(g.da AS INT64)) AS obs_date,
    s.country,
    g.max,
    g.min,
    g.temp
  FROM `bigquery-public-data.noaa_gsod.gsod2023` AS g
  JOIN `bigquery-public-data.noaa_gsod.stations`  AS s
        ON g.stn = s.usaf
       AND g.wban = s.wban
  WHERE g.year = '2023'
    AND g.mo   = '10'                             -- October only
    -- keep only rows with real (non-placeholder) temperature values
    AND g.temp NOT IN (9999.9)
    AND g.max  NOT IN (9999.9, 999.9)
    AND g.min  NOT IN (9999.9, 999.9)
    AND s.country IN ('US','UK')                  -- limit to the two countries of interest
),
daily_country AS (    -- aggregate per country/day
  SELECT
    obs_date,
    country,
    MAX(max)        AS daily_max,
    MIN(min)        AS daily_min,
    AVG(temp)       AS daily_mean
  FROM valid_obs
  GROUP BY obs_date, country
)
SELECT
  us.obs_date                         AS date,
  ROUND(us.daily_max  - uk.daily_max , 4) AS max_temp_diff,
  ROUND(us.daily_min  - uk.daily_min , 4) AS min_temp_diff,
  ROUND(us.daily_mean - uk.daily_mean, 4) AS mean_temp_diff
FROM daily_country AS us
JOIN daily_country AS uk
  ON  us.obs_date = uk.obs_date
WHERE us.country = 'US'
  AND uk.country = 'UK'
ORDER BY date;