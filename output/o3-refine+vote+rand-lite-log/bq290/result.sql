-- Difference (U​S – U​K) in daily maximum, minimum and mean temperatures  
-- for every day in October 2023.  Missing / placeholder values (≥ 9999)
-- are excluded.  Only days where both U​S and U​K have valid data are returned.

WITH gsod_oct23 AS (
  SELECT
    DATE(CAST(g.year AS INT64),
         CAST(g.mo   AS INT64),
         CAST(g.da   AS INT64))                AS obs_date,
    s.country                                   AS country,
    g.`max`                                     AS max_temp,
    g.`min`                                     AS min_temp,
    g.temp                                      AS mean_temp
  FROM `bigquery-public-data.noaa_gsod.gsod2023` AS g
  JOIN `bigquery-public-data.noaa_gsod.stations` AS s
    ON g.stn  = s.usaf
   AND g.wban = s.wban
  WHERE g.year = '2023'
    AND g.mo   = '10'                -- October
    AND s.country IN ('US','UK')     -- countries of interest
    -- remove missing / invalid temperature values
    AND g.`max`  IS NOT NULL AND g.`max`  < 9999
    AND g.`min`  IS NOT NULL AND g.`min`  < 9999
    AND g.temp   IS NOT NULL AND g.temp  < 9999
),

country_day_stats AS (
  SELECT
    obs_date,
    country,
    AVG(max_temp)  AS avg_max_temp,
    AVG(min_temp)  AS avg_min_temp,
    AVG(mean_temp) AS avg_mean_temp
  FROM gsod_oct23
  GROUP BY obs_date, country
),

us_uk_paired AS (
  SELECT
    u.obs_date,
    u.avg_max_temp  AS us_avg_max,
    k.avg_max_temp  AS uk_avg_max,
    u.avg_min_temp  AS us_avg_min,
    k.avg_min_temp  AS uk_avg_min,
    u.avg_mean_temp AS us_avg_mean,
    k.avg_mean_temp AS uk_avg_mean
  FROM  country_day_stats AS u
  JOIN  country_day_stats AS k
    ON  u.obs_date = k.obs_date
  WHERE u.country = 'US'
    AND k.country = 'UK'
)

SELECT
  obs_date                                   AS date,
  us_avg_max  - uk_avg_max  AS diff_max_temperature,
  us_avg_min  - uk_avg_min  AS diff_min_temperature,
  us_avg_mean - uk_avg_mean AS diff_avg_temperature
FROM us_uk_paired
ORDER BY date;