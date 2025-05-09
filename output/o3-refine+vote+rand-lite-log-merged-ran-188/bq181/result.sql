-- Percentage of stations whose 2022 records are ≥ 90 % “valid”  
--   (temp, max and min all present and ≠ 9999.9)  
--   among all stations that reported in 2022 (excluding dummy USAF '999999')
WITH per_day AS (
  SELECT
    stn,
    CASE
      WHEN temp IS NOT NULL AND max IS NOT NULL AND min IS NOT NULL
           AND temp <> 9999.9 AND max <> 9999.9 AND min <> 9999.9
      THEN 1 ELSE 0
    END AS is_valid
  FROM `bigquery-public-data.noaa_gsod.gsod2022`
  WHERE stn <> '999999'          -- omit invalid station code
),
per_station AS (
  SELECT
    stn,
    COUNT(*)            AS total_days,
    SUM(is_valid)       AS valid_days
  FROM per_day
  GROUP BY stn
),
summary AS (
  SELECT
    COUNTIF( SAFE_DIVIDE(valid_days , total_days) >= 0.9 ) AS stations_meeting_90pct,
    COUNT(*)                                               AS all_stations
  FROM per_station
)
SELECT
  ROUND( SAFE_DIVIDE(stations_meeting_90pct , all_stations) * 100 , 2)
    AS pct_stations_ge_90pct_valid
FROM summary;