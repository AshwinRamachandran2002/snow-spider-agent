-- Count long-running GSOD stations that reported valid
-- temperature data on ≥ 90 % of 2019’s days (≥ 329 of 365)

WITH good_2019 AS (
  -- days whose temp / max / min are NOT the sentinel “missing” values
  SELECT
    stn,
    wban,
    COUNT(*) AS good_days_2019
  FROM `bigquery-public-data.noaa_gsod.gsod2019`
  WHERE temp < 9000          -- 9999.9 indicates “missing”
    AND max  < 9000
    AND min  < 9000
  GROUP BY stn, wban
),
long_record AS (
  -- stations whose period-of-record spans at least 2000-01-01 → 2019-06-30
  SELECT
    usaf AS stn,
    wban,
    `begin`,
    `end`
  FROM `bigquery-public-data.noaa_gsod.stations`
  WHERE `begin` <= '20000101'
    AND `end`   >= '20190630'
),
qualified AS (
  SELECT CONCAT(g.stn,'-',g.wban) AS station_id
  FROM   good_2019  AS g
  JOIN   long_record AS l
    ON   g.stn  = l.stn
   AND   g.wban = l.wban
  WHERE  g.good_days_2019 >= 329     -- ≥ 90 % of 365 days
)

SELECT COUNT(*) AS stations_meeting_90pct_criteria
FROM qualified;