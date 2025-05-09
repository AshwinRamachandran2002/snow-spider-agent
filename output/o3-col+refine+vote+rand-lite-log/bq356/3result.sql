-- Stations with ≥ 90 % of 2019 days having all three temperature
-- fields present, and whose station record spans 1-Jan-2000‒30-Jun-2019
WITH valid_2019_days AS (
  SELECT
    stn,
    wban,
    COUNT(*) AS valid_temp_days
  FROM `bigquery-public-data.noaa_gsod.gsod2019`
  WHERE temp < 9999.0          -- non-missing mean temp
    AND max  < 9999.0          -- non-missing max temp
    AND min  < 9999.0          -- non-missing min temp
  GROUP BY stn, wban
),
eligible_stations AS (
  SELECT
    usaf AS stn,
    wban
  FROM `bigquery-public-data.noaa_gsod.stations`
  WHERE CAST(begin AS INT64) <= 20000101   -- began on/before 1-Jan-2000
    AND CAST(`end`  AS INT64) >= 20190630  -- active through ≥ 30-Jun-2019
),
qualifying_stations AS (
  SELECT
    v.stn,
    v.wban
  FROM valid_2019_days v
  JOIN eligible_stations e
    ON v.stn = e.stn
   AND v.wban = e.wban
  WHERE v.valid_temp_days >= 0.9 * 365     -- ≥ 90 % of year
)
SELECT
  COUNT(*) AS stations_meeting_90pct_threshold
FROM qualifying_stations;