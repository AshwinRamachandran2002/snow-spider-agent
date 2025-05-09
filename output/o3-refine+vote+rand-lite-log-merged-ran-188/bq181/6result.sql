-- Percentage of stations that have valid temp / max / min 
-- on ≥90 % of their 2022 reporting days
WITH day_level AS (
  SELECT
    g.stn,
    g.temp,
    g.`max`,
    g.`min`
  FROM `bigquery-public-data.noaa_gsod.gsod2022` AS g
  JOIN `bigquery-public-data.noaa_gsod.stations`  AS s
    ON g.stn = s.usaf
   AND g.wban = s.wban
  WHERE s.usaf <> '999999'          -- exclude dummy stations
),
per_station AS (
  SELECT
    stn,
    COUNT(*) AS total_days,
    COUNTIF(
      temp NOT IN (9999.9) AND `max` NOT IN (9999.9) AND `min` NOT IN (9999.9)
      AND temp IS NOT NULL AND `max` IS NOT NULL AND `min` IS NOT NULL
    ) AS valid_days
  FROM day_level
  GROUP BY stn
),
good AS (                           -- stations with ≥90 % valid days
  SELECT stn
  FROM   per_station
  WHERE  SAFE_DIVIDE(valid_days, total_days) >= 0.90
)
SELECT
  ROUND(
    100 * (SELECT COUNT(*) FROM good) / (SELECT COUNT(*) FROM per_station),
    2
  ) AS pct_stations_90pct_valid_2022;