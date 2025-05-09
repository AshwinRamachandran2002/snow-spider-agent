-- Count GSOD stations that
-- 1) have a period of record beginning ≤ 2000-01-01 and extending ≥ 2019-06-30
-- 2) reported valid (≠ 9999.9) temp, max and min on at least 90 % of 2019 days
WITH period_ok AS (
  SELECT
    usaf AS stn
  FROM `bigquery-public-data.noaa_gsod.stations`
  WHERE CAST(begin AS INT64) <= 20000101
    AND (SAFE_CAST(`end` AS INT64) >= 20190630 OR `end` = '')
),
valid_day_counts AS (
  SELECT
    stn,
    COUNTIF( temp NOT IN (9999.9)
          AND max  NOT IN (9999.9)
          AND min  NOT IN (9999.9) ) AS valid_days_2019
  FROM `bigquery-public-data.noaa_gsod.gsod2019`
  GROUP BY stn
),
eligible_stations AS (
  SELECT
    v.stn
  FROM valid_day_counts v
  JOIN period_ok        p USING (stn)
  WHERE v.valid_days_2019 >= 0.9 * 365          -- ≥ 90 % of possible days in 2019
)
SELECT COUNT(*) AS stations_at_least_90pct
FROM eligible_stations;