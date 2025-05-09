-- Percentage of stations that have valid temperature, max, and min
-- values (not NULL and not 9999.9) for at least 90 % of calendar
-- days in 2022, among all stations that reported any data in 2022
-- and with a valid USAF identifier (STN <> '999999').

WITH station_day_quality AS (
  SELECT
    stn,                                                -- USAF station ID
    COUNTIF(
      temp IS NOT NULL AND temp <> 9999.9  -- mean temperature
      AND max  IS NOT NULL AND max  <> 9999.9  -- daily maximum
      AND min  IS NOT NULL AND min  <> 9999.9  -- daily minimum
    ) AS valid_day_cnt                                   -- “good” days
  FROM
    `bigquery-public-data.noaa_gsod.gsod2022`
  WHERE
    stn <> '999999'                                      -- ignore invalid ID
  GROUP BY
    stn
),

station_coverage AS (
  SELECT
    stn,
    valid_day_cnt,
    -- 90 % of the 365 days in 2022  →  329.0 days
    valid_day_cnt >= 0.9 * 365 AS has_90pct_coverage
  FROM
    station_day_quality
),

summary AS (
  SELECT
    COUNTIF(has_90pct_coverage) AS stations_meeting_criterion,
    COUNT(*)                        AS total_reporting_stations
  FROM
    station_coverage
)

SELECT
  ROUND(
    100.0 * stations_meeting_criterion / total_reporting_stations,
    2
  ) AS pct_stations_with_90pct_valid_data_2022
FROM
  summary;