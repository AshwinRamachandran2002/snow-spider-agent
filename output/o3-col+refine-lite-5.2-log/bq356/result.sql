-- Stations that started on/before 1‑Jan‑2000, were still active on/after 30‑Jun‑2019,
-- and logged valid temperature data on at least 90 % of 2019’s 365 days (≥ 329 days).
WITH valid_2019 AS (
  SELECT
    stn  AS usaf,
    wban,
    COUNT(*) AS valid_days_2019
  FROM `bigquery-public-data.noaa_gsod.gsod2019`
  WHERE temp <> 9999.9        -- discard missing daily mean temperature
    AND `max` <> 999.9        -- discard missing daily maximum temperature
    AND `min` <> 999.9        -- discard missing daily minimum temperature
  GROUP BY stn, wban
),
eligible_stations AS (
  SELECT
    usaf,
    wban
  FROM `bigquery-public-data.noaa_gsod.stations`
  WHERE begin <= '20000101'   -- record began on or before 1‑Jan‑2000
    AND `end`  >= '20190630'  -- record extends through at least 30‑Jun‑2019
)
SELECT
  COUNT(*) AS stations_meeting_90pct
FROM valid_2019 v
JOIN eligible_stations e
USING (usaf, wban)
WHERE v.valid_days_2019 >= 329;   -- 90 % of 365