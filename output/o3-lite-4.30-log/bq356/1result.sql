WITH eligible_stations AS (
  SELECT usaf, wban
  FROM `bigquery-public-data.noaa_gsod.stations`
  WHERE CAST(`begin` AS INT64) <= 20000101
    AND CAST(`end`   AS INT64) >= 20190630
),
valid_day_counts AS (
  SELECT
    g.stn  AS usaf,
    g.wban AS wban,
    COUNT(*) AS valid_days_2019
  FROM `bigquery-public-data.noaa_gsod.gsod2019` AS g
  JOIN eligible_stations AS e
    ON g.stn  = e.usaf
   AND g.wban = e.wban
  WHERE g.temp <> 9999.9
    AND g.max  <> 9999.9
    AND g.min  <> 9999.9
  GROUP BY usaf, wban
)
SELECT COUNT(*) AS stations_meeting_criteria
FROM valid_day_counts
WHERE valid_days_2019 >= 329;