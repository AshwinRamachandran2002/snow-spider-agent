-- Percentage of stations that reported *valid* temperature data
-- (temp, max, min all present and ≠ 9999.9) on ≥ 90 % of days in 2022
-- among all stations with a real USAF identifier (≠ '999999')

WITH daily_flags AS (
  SELECT
    g.stn,
    -- 1 if the day’s temperature numbers are usable, else 0
    CASE
      WHEN g.temp IS NOT NULL
       AND g.max  IS NOT NULL
       AND g.min  IS NOT NULL
       AND g.temp <> 9999.9
       AND g.max  <> 9999.9
       AND g.min  <> 9999.9
      THEN 1 ELSE 0
    END AS valid_day
  FROM `bigquery-public-data.noaa_gsod.gsod2022` AS g
  JOIN `bigquery-public-data.noaa_gsod.stations`  AS s
    ON s.usaf = g.stn                -- link to metadata
  WHERE s.usaf <> '999999'           -- keep only real stations
),

per_station AS (
  SELECT
    stn,
    SAFE_DIVIDE(SUM(valid_day), COUNT(*)) AS valid_ratio   -- share of good days
  FROM daily_flags
  GROUP BY stn
),

totals AS (
  SELECT
    COUNTIF(valid_ratio >= 0.90) AS stations_ge90pct_valid,
    COUNT(*)                     AS total_reporting_stations
  FROM per_station
)

SELECT
  stations_ge90pct_valid,
  total_reporting_stations,
  ROUND(100 * SAFE_DIVIDE(stations_ge90pct_valid,
                           total_reporting_stations), 2) AS percent_good
FROM totals;