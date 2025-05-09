-- Stations that meet all the stated conditions and have ≥ 90 % of possible
-- valid-temperature days (≥ 329) in 2019
WITH valid_days AS (
  SELECT
    CONCAT(stn, '-', wban) AS station_id,
    COUNT(*)              AS valid_days_2019
  FROM
    `bigquery-public-data.noaa_gsod.gsod2019`
  WHERE
    temp < 9999          -- non-missing mean temperature
    AND `max` < 999      -- non-missing daily maximum temperature
    AND `min` < 999      -- non-missing daily minimum temperature
  GROUP BY
    station_id
),
eligible_stations AS (
  SELECT
    CONCAT(usaf, '-', wban) AS station_id
  FROM
    `bigquery-public-data.noaa_gsod.stations`
  WHERE
    SAFE_CAST(begin AS INT64) <= 20000101   -- began on/before 1-Jan-2000
    AND SAFE_CAST(`end`  AS INT64) >= 20190630   -- still active on 30-Jun-2019
)
SELECT
  COUNT(*) AS stations_at_90pct_or_more
FROM
  valid_days
JOIN
  eligible_stations
USING (station_id)
WHERE
  valid_days_2019 >= 329;   -- 90 % of 365