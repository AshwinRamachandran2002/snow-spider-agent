-- Count GSOD stations meeting the criteria described
WITH eligible_stations AS (
  SELECT
    usaf,
    wban
  FROM
    `bigquery-public-data.noaa_gsod.stations`
  WHERE
    SAFE_CAST(`begin` AS INT64) <= 20000101      -- began no later than 1 Jan 2000
    AND SAFE_CAST(`end`   AS INT64) >= 20190630   -- active through at least 30 Jun 2019
),
daily_valid_counts AS (
  SELECT
    g.stn  AS usaf,
    g.wban AS wban,
    COUNT(*) AS valid_days_2019
  FROM
    `bigquery-public-data.noaa_gsod.gsod2019` AS g
  JOIN
    eligible_stations AS e
  ON
    g.stn  = e.usaf
    AND g.wban = e.wban
  -- retain rows with non‑missing temperature data
  WHERE
        g.temp IS NOT NULL AND g.temp <> 9999.9
    AND g.`max` IS NOT NULL AND g.`max` <> 9999.9
    AND g.`min` IS NOT NULL AND g.`min` <> 9999.9
  GROUP BY
    usaf, wban
)
SELECT
  COUNT(*) AS station_count_90pct_or_more
FROM
  daily_valid_counts
WHERE
  valid_days_2019 >= CEIL(365 * 0.90);  -- ≥329 valid days