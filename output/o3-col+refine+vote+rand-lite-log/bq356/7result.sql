-- Number of NOAA GSOD stations with ≥ 90 % valid temperature days in 2019
WITH valid_2019 AS (
  SELECT
    stn,
    COUNTIF(
      temp < 9999.0          -- mean temperature present
      AND `max` < 999.0      -- daily maximum present
      AND `min` < 999.0      -- daily minimum present
    ) AS valid_days_2019
  FROM
    `bigquery-public-data.noaa_gsod.gsod2019`
  GROUP BY
    stn
),
eligible_stations AS (
  SELECT
    usaf AS stn
  FROM
    `bigquery-public-data.noaa_gsod.stations`
  WHERE
    begin <= '20000101'   -- record began on or before 1 Jan 2000
    AND `end` >= '20190630'  -- record extends beyond 30 Jun 2019
),
qualified AS (
  SELECT
    v.stn
  FROM
    valid_2019 AS v
  JOIN
    eligible_stations AS e
  USING (stn)
  WHERE
    v.valid_days_2019 >= 329   -- 90 % of 365 days
)
SELECT
  COUNT(*) AS num_stations_90pct_or_more
FROM
  qualified;