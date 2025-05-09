WITH base AS (
  -- daily reports for 2022 with a non‑dummy USAF identifier
  SELECT
    LPAD(stn, 6, '0')             AS usaf,          -- 6‑digit USAF code
    DATE(CONCAT(year, '-', mo, '-', da)) AS obs_day,
    temp,
    `max`,
    `min`
  FROM `bigquery-public-data.noaa_gsod.gsod2022`
  WHERE LPAD(stn, 6, '0') <> '999999'               -- discard dummy station id
),

per_station AS (
  SELECT
    usaf,
    COUNTIF( temp IS NOT NULL  AND temp <> 9999.9
          AND `max` IS NOT NULL AND `max` <> 9999.9
          AND `min` IS NOT NULL AND `min` <> 9999.9) AS good_days
  FROM base
  GROUP BY usaf
),

eligible AS (
  SELECT
    usaf,
    good_days,
    good_days / 365.0 AS good_fraction              -- 2022 has 365 days
  FROM per_station
),

summary AS (
  SELECT
    COUNTIF(good_fraction >= 0.90) AS stations_meeting_90pct,
    COUNT(*)                       AS total_stations
  FROM eligible
)

SELECT
  ROUND( SAFE_DIVIDE(stations_meeting_90pct, total_stations) * 100 , 4) 
    AS percent_of_stations_with_90pct_good_data
FROM summary;