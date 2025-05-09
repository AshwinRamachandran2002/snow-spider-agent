-- Percentage of stations that have valid temperature (temp, max, min not NULL/9999.9)
-- on at least 90 % of their reported days in 2022
WITH per_station AS (
  SELECT
    g.stn,                              -- station id (USAF)
    COUNT(*) AS total_days,             -- all days reported in 2022
    SUM(
      CASE
        WHEN g.temp IS NOT NULL AND g.max IS NOT NULL AND g.min IS NOT NULL
             AND g.temp <> 9999.9 AND g.max <> 9999.9 AND g.min <> 9999.9
        THEN 1 ELSE 0
      END
    ) AS valid_days                     -- days with wholly valid temperature data
  FROM `bigquery-public-data.noaa_gsod.gsod2022` AS g
  JOIN `bigquery-public-data.noaa_gsod.stations` AS s
    ON g.stn = s.usaf                   -- ensure the id appears in the station list
  WHERE s.usaf <> '999999'              -- keep only stations with a valid USAF id
  GROUP BY g.stn
),
ratios AS (
  SELECT
    stn,
    SAFE_DIVIDE(valid_days, total_days) AS valid_ratio
  FROM per_station
),
totals AS (
  SELECT
    COUNTIF(valid_ratio >= 0.90) AS stations_meeting_90pct,
    COUNT(*)                     AS total_stations_considered
  FROM ratios
)
SELECT
  ROUND(
    100 * stations_meeting_90pct / total_stations_considered, 2
  ) AS percent_stations_with_ge90pct_valid_days
FROM totals;