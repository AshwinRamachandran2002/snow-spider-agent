-- Percentage of stations that reported valid temperature
-- (temp / max / min not NULL or 9999.9) for ≥ 90 % of 2022
WITH station_list AS (          -- all stations in GSOD with a valid USAF id
  SELECT DISTINCT usaf AS stn
  FROM `bigquery-public-data.noaa_gsod.stations`
  WHERE usaf <> '999999'
),
valid_days_per_stn AS (         -- how many 2022 days each station has valid data
  SELECT
    stn,
    COUNT(DISTINCT PARSE_DATE('%Y%m%d', CONCAT(year, mo, da))) AS valid_days
  FROM `bigquery-public-data.noaa_gsod.gsod2022`
  WHERE
    stn <> '999999'
    AND temp IS NOT NULL AND temp <> 9999.9
    AND `max` IS NOT NULL AND `max` <> 9999.9
    AND `min` IS NOT NULL AND `min` <> 9999.9
  GROUP BY stn
),
stations_meeting_threshold AS ( -- those with ≥ 90 % of the 365 days
  SELECT stn
  FROM valid_days_per_stn
  WHERE valid_days >= 0.9 * 365        -- 329 or more valid days
)
SELECT
  ROUND(
    SAFE_DIVIDE(
      (SELECT COUNT(*) FROM stations_meeting_threshold),
      (SELECT COUNT(*) FROM station_list)
    ) * 100
  ,4) AS pct_stations_with_valid_2022_data
;