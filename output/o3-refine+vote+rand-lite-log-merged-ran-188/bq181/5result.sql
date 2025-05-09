-- Percentage of GSOD stations that reported valid temp/max/min on ≥90% of days in 2022
WITH per_station AS (
  SELECT
    stn,
    COUNT(*) AS total_days,
    COUNTIF(
      temp IS NOT NULL  AND temp <> 9999.9 AND
      max  IS NOT NULL  AND max  <> 9999.9 AND
      min  IS NOT NULL  AND min  <> 9999.9
    ) AS valid_days
  FROM `bigquery-public-data.noaa_gsod.gsod2022`
  WHERE stn <> '999999'                      -- remove placeholder USAF id
  GROUP BY stn
),
summary AS (
  SELECT
    COUNT(*) AS total_stations,
    SUM(CASE WHEN SAFE_DIVIDE(valid_days, total_days) >= 0.9 THEN 1 ELSE 0 END) AS passing_stations
  FROM per_station
)
SELECT
  ROUND(100 * SAFE_DIVIDE(passing_stations, total_stations), 4) AS pct_stations_passing_2022
FROM summary;