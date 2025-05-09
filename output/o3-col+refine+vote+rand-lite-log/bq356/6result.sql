-- Number of GSOD stations (period-of-record began ≤ 2000-01-01, still active ≥ 2019-06-30)
-- that reported valid temp/max/min values on at least 90 % (≥ 329 days) of 2019
WITH valid_2019 AS (
  SELECT
    stn,
    wban,
    COUNT(*) AS valid_days_2019
  FROM `bigquery-public-data.noaa_gsod.gsod2019`
  WHERE temp < 9999.9          -- discard missing-value codes
    AND max  < 9999.9
    AND min  < 9999.9
  GROUP BY stn, wban
),
eligible_stations AS (
  SELECT
    usaf AS stn,
    wban
  FROM `bigquery-public-data.noaa_gsod.stations`
  WHERE SAFE.PARSE_DATE('%Y%m%d', begin)                              <= DATE '2000-01-01'
    AND COALESCE(SAFE.PARSE_DATE('%Y%m%d', `end`), DATE '2100-01-01') >= DATE '2019-06-30'
)
SELECT
  COUNT(*) AS stations_at_least_90pct_days_2019
FROM eligible_stations AS e
JOIN valid_2019       AS v
  ON e.stn  = v.stn
 AND e.wban = v.wban
WHERE v.valid_days_2019 >= 329;   -- 90 % of 365 days