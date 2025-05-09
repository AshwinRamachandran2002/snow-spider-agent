-- Daily temperature differences (US – UK) for October 2023
WITH daily_country AS (
  SELECT
    DATE(CONCAT(g.year,'-',g.mo,'-',g.da))                 AS obs_date,
    s.country                                              AS country,
    MAX(g.max)                                             AS max_temp,   -- highest station max
    MIN(g.min)                                             AS min_temp,   -- lowest station min
    AVG(g.temp)                                            AS avg_temp    -- mean of station means
  FROM `bigquery-public-data.noaa_gsod.gsod2023` AS g
  JOIN `bigquery-public-data.noaa_gsod.stations`  AS s
       ON g.stn  = s.usaf
      AND g.wban = s.wban
  WHERE g.year = '2023'
    AND g.mo   = '10'                      -- October
    AND s.country IN ('US','UK')           -- keep only US & UK stations
    -- discard clearly invalid/missing values
    AND g.max  IS NOT NULL AND g.max  < 900
    AND g.min  IS NOT NULL AND g.min  < 900
    AND g.temp IS NOT NULL AND g.temp < 9000
  GROUP BY obs_date, country
),
us AS (
  SELECT obs_date, max_temp AS us_max, min_temp AS us_min, avg_temp AS us_avg
  FROM   daily_country
  WHERE  country = 'US'
),
uk AS (
  SELECT obs_date, max_temp AS uk_max, min_temp AS uk_min, avg_temp AS uk_avg
  FROM   daily_country
  WHERE  country = 'UK'
)
SELECT
  u.obs_date                                                  AS date,
  u.us_max - k.uk_max                                         AS diff_max_temperature,
  u.us_min - k.uk_min                                         AS diff_min_temperature,
  u.us_avg - k.uk_avg                                         AS diff_avg_temperature
FROM us AS u
JOIN uk AS k
  ON u.obs_date = k.obs_date
ORDER BY date;