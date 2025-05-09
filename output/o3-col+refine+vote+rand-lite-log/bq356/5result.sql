WITH valid_days AS (
  SELECT
    stn,
    wban,
    COUNT(*) AS valid_days_2019
  FROM `bigquery-public-data.noaa_gsod.gsod2019`
  WHERE temp NOT IN (999.9, 9999.9)   -- exclude missing temps
    AND `max` <> 999.9                -- exclude missing max temps
    AND `min` <> 999.9                -- exclude missing min temps
  GROUP BY stn, wban
),
eligible_stations AS (
  SELECT
    usaf AS stn,
    wban
  FROM `bigquery-public-data.noaa_gsod.stations`
  WHERE SAFE_CAST(`begin` AS INT64) <= 20000101   -- began on/Before 2000-01-01
    AND SAFE_CAST(`end`   AS INT64) >= 20190630   -- active through ≥ 2019-06-30
)
SELECT
  COUNT(*) AS stations_with_90pct_or_more_valid_days_2019
FROM valid_days v
JOIN eligible_stations e
  ON v.stn = e.stn
 AND v.wban = e.wban
WHERE v.valid_days_2019 >= 329;   -- ≥ 90 % of 365 days