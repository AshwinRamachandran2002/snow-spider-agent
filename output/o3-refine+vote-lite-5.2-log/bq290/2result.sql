-- Difference in daily maximum, minimum and mean temperatures (US – UK)
-- for every day of October 2023.  Missing / invalid temperature values
-- (≥9 000 °F, the GSOD missing‑value flag) are discarded.

WITH valid_obs AS (
  SELECT
    DATE(CAST(g.year AS INT64), CAST(g.mo AS INT64), CAST(g.da AS INT64)) AS obs_date,
    -- treat both possible 2‑letter codes for the United Kingdom
    CASE
      WHEN s.country = 'US' THEN 'US'
      WHEN s.country IN ('UK', 'GB') THEN 'UK'
    END                                                  AS country_grp,
    CAST(g.max AS FLOAT64)  AS max_temp,
    CAST(g.min AS FLOAT64)  AS min_temp,
    CAST(g.temp AS FLOAT64) AS mean_temp
  FROM `bigquery-public-data.noaa_gsod.gsod2023`  AS g
  JOIN `bigquery-public-data.noaa_gsod.stations` AS s
    ON g.stn  = s.usaf
   AND g.wban = s.wban
  WHERE g.year = '2023'
    AND g.mo   = '10'                       -- October only
    -- keep only US / UK stations
    AND s.country IN ('US','UK','GB')
    -- discard missing / sentinel temperature values
    AND g.max  < 9000
    AND g.min  < 9000
    AND g.temp < 9000
),
daily_country AS (
  /*  Aggregate once per country per day  */
  SELECT
    obs_date,
    country_grp,
    MAX(max_temp)        AS day_max,   -- highest reported max temp in country that day
    MIN(min_temp)        AS day_min,   -- lowest reported min temp in country that day
    AVG(mean_temp)       AS day_mean   -- average of station mean temps
  FROM valid_obs
  GROUP BY obs_date, country_grp
),
pivot AS (
  /*  Put US and UK onto the same row for subtraction  */
  SELECT
    obs_date,
    MAX(CASE WHEN country_grp = 'US' THEN day_max  END) AS us_max,
    MAX(CASE WHEN country_grp = 'UK' THEN day_max  END) AS uk_max,
    MAX(CASE WHEN country_grp = 'US' THEN day_min  END) AS us_min,
    MAX(CASE WHEN country_grp = 'UK' THEN day_min  END) AS uk_min,
    MAX(CASE WHEN country_grp = 'US' THEN day_mean END) AS us_mean,
    MAX(CASE WHEN country_grp = 'UK' THEN day_mean END) AS uk_mean
  FROM daily_country
  GROUP BY obs_date
)
SELECT
  obs_date                                           AS date,
  us_max  - uk_max   AS max_temperature_diff,
  us_min  - uk_min   AS min_temperature_diff,
  us_mean - uk_mean  AS avg_temperature_diff
FROM pivot
-- retain only days where both countries had observations
WHERE us_max IS NOT NULL
  AND uk_max IS NOT NULL
ORDER BY date;