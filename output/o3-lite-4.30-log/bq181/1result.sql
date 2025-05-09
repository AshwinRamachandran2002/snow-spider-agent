WITH station_days AS (
  SELECT
    g.stn,
    COUNT(*) AS total_days,
    COUNTIF(
      g.temp IS NOT NULL
      AND g.max IS NOT NULL
      AND g.min IS NOT NULL
      AND g.temp <> 9999.9
      AND g.max  <> 9999.9
      AND g.min  <> 9999.9
    ) AS valid_days
  FROM `bigquery-public-data.noaa_gsod.gsod2022` AS g
  JOIN `bigquery-public-data.noaa_gsod.stations` AS s
    ON g.stn = s.usaf
  WHERE s.usaf <> '999999'
  GROUP BY g.stn
),
station_coverage AS (
  SELECT
    stn,
    SAFE_DIVIDE(valid_days, total_days) AS pct_valid
  FROM station_days
),
summary AS (
  SELECT
    COUNT(DISTINCT CASE WHEN pct_valid >= 0.90 THEN stn END) AS stations_meeting_threshold,
    COUNT(DISTINCT stn) AS total_stations
  FROM station_coverage
)
SELECT
  ROUND(SAFE_DIVIDE(stations_meeting_threshold, total_stations) * 100, 4) AS percentage_valid_stations
FROM summary;