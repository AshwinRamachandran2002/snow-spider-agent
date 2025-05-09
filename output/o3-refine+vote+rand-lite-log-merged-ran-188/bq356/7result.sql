WITH period_ok AS (
  SELECT
    usaf,
    wban
  FROM `bigquery-public-data.noaa_gsod.stations`
  WHERE
    SAFE_CAST(`begin` AS INT64) IS NOT NULL
    AND SAFE_CAST(`begin` AS INT64) <= 20000101      -- began on or before 1 Jan 2000
    AND SAFE_CAST(`end`   AS INT64) IS NOT NULL
    AND SAFE_CAST(`end`   AS INT64) >= 20190630      -- active through ≥ 30 Jun 2019
),
valid_days_2019 AS (
  SELECT
    stn  AS usaf,
    wban,
    COUNTIF(temp < 9999 AND `max` < 9999 AND `min` < 9999) AS valid_day_cnt
  FROM `bigquery-public-data.noaa_gsod.gsod2019`
  GROUP BY stn, wban
),
combined AS (
  SELECT
    p.usaf,
    p.wban,
    v.valid_day_cnt
  FROM period_ok p
  JOIN valid_days_2019 v
  ON p.usaf = v.usaf AND p.wban = v.wban
)
SELECT
  COUNT(*) AS stations_meeting_90pct_coverage
FROM combined
WHERE valid_day_cnt >= 0.9 * 365;   -- at least 329 valid temperature days