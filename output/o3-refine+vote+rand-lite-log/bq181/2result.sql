-- percentage of stations that reported valid temperature data
-- (temp, max, min all present and not 9999.9)
-- on at least 90 % (>=329) of the 365 calendar days in 2022

WITH daily_valid AS (
  SELECT
    stn,                       -- USAF station identifier in GSOD table
    COUNTIF(
      temp IS NOT NULL AND temp != 9999.9
      AND `max` IS NOT NULL  AND `max` != 9999.9
      AND `min` IS NOT NULL  AND `min` != 9999.9
    ) AS valid_day_cnt         -- number of 2022 days with good data
  FROM `bigquery-public-data.noaa_gsod.gsod2022`
  GROUP BY stn
),
filtered_stations AS (         -- keep stations with real USAF id
  SELECT dv.*
  FROM daily_valid dv
  JOIN `bigquery-public-data.noaa_gsod.stations` st
    ON dv.stn = st.usaf
  WHERE st.usaf <> '999999'    -- exclude invalid identifier
),
summary AS (
  SELECT
    COUNT(*)                                         AS total_stations,
    COUNTIF(valid_day_cnt >= 0.9 * 365)              AS stations_90pct
  FROM filtered_stations
)
SELECT
  ROUND(100 * stations_90pct / total_stations, 4)   AS percent_stations_90pct_valid
FROM summary;