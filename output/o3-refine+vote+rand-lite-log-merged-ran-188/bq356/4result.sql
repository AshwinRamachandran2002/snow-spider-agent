-- Stations that started on/before 2000‑01‑01, were still active 2019‑06‑30,
-- and reported valid temperature (temp, max, min) on ≥90 % of 2019 days
WITH period_ok AS (   -- stations whose period of record spans the required dates
  SELECT
    usaf,
    wban
  FROM `bigquery-public-data.noaa_gsod.stations`
  WHERE CAST(`begin` AS INT64) <= 20000101      -- service began by 1‑Jan‑2000
    AND CAST(`end`   AS INT64) >= 20190630      -- active through 30‑Jun‑2019
),
valid_2019 AS (       -- count days in 2019 with all three temperatures present
  SELECT
    stn  AS usaf,
    wban,
    COUNT(*) AS valid_day_cnt
  FROM `bigquery-public-data.noaa_gsod.gsod2019`
  WHERE temp < 9999.9         -- mean temperature not missing
    AND `max` < 9999.9        -- maximum temperature not missing
    AND `min` < 9999.9        -- minimum temperature not missing
  GROUP BY usaf, wban
),
high_coverage AS (    -- stations with ≥90 % of 365 (= 329) valid days
  SELECT v.usaf, v.wban
  FROM   valid_2019 v
  JOIN   period_ok  p
  ON     v.usaf = p.usaf AND v.wban = p.wban
  WHERE  v.valid_day_cnt >= 329
)
SELECT COUNT(*) AS station_count
FROM   high_coverage;