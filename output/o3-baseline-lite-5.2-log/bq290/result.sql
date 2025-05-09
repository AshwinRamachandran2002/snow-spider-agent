-- Daily difference in max, min and mean temperatures
-- between U.S. and U.K. GSOD stations, Oct‑2023
WITH daily_obs AS (
  SELECT
    -- compose a DATE from the separate Y/M/D string fields
    DATE(CAST(year AS INT64), CAST(mo AS INT64), CAST(da AS INT64)) AS obs_date,
    stn,                              -- station USAF id
    temp      AS mean_temp_station,    -- daily mean temperature (°F)
    `max`     AS max_temp_station,     -- station daily maximum (°F)
    `min`     AS min_temp_station      -- station daily minimum (°F)
  FROM `bigquery-public-data.noaa_gsod.gsod2023`
  WHERE year = '2023'
    AND mo   = '10'                    -- October only
    -- discard “missing / invalid” temperature values
    AND temp < 9000
    AND `max` < 9000
    AND `min` < 9000
),
joined AS (
  SELECT
    o.obs_date,
    s.country,
    o.mean_temp_station,
    o.max_temp_station,
    o.min_temp_station
  FROM daily_obs o
  JOIN `bigquery-public-data.noaa_gsod.stations` s
    ON o.stn = s.usaf
  WHERE s.country IN ('US','UK')       -- keep only U.S. and U.K. stations
),
country_day AS (
  -- aggregate one line per country‑day
  SELECT
    obs_date,
    country,
    MAX(max_temp_station)  AS country_max,     -- warmest station that day
    MIN(min_temp_station)  AS country_min,     -- coldest station that day
    AVG(mean_temp_station) AS country_mean     -- average of station means
  FROM joined
  GROUP BY obs_date, country
)
SELECT
  obs_date,
  -- individual country statistics (optional – comment out if not needed)
  MAX(CASE WHEN country = 'US' THEN country_max END)  AS us_max,
  MAX(CASE WHEN country = 'UK' THEN country_max END)  AS uk_max,
  MAX(CASE WHEN country = 'US' THEN country_min END)  AS us_min,
  MAX(CASE WHEN country = 'UK' THEN country_min END)  AS uk_min,
  MAX(CASE WHEN country = 'US' THEN country_mean END) AS us_mean,
  MAX(CASE WHEN country = 'UK' THEN country_mean END) AS uk_mean,

  -- requested differences (U.S. minus U.K.)
  MAX(CASE WHEN country = 'US' THEN country_max END)
  - MAX(CASE WHEN country = 'UK' THEN country_max END)  AS diff_max_temp,

  MAX(CASE WHEN country = 'US' THEN country_min END)
  - MAX(CASE WHEN country = 'UK' THEN country_min END)  AS diff_min_temp,

  MAX(CASE WHEN country = 'US' THEN country_mean END)
  - MAX(CASE WHEN country = 'UK' THEN country_mean END) AS diff_mean_temp
FROM country_day
GROUP BY obs_date
ORDER BY obs_date;