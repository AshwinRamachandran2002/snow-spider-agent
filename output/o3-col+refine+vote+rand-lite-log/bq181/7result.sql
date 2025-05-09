-- Percentage of stations with ≥90 % valid temperature data in 2022
WITH per_station AS (
  SELECT
    g.stn,
    COUNT(*) AS total_days,
    SUM(
      CASE
        WHEN g.temp IS NOT NULL AND g.temp <> 9999.9
         AND g.max  IS NOT NULL AND g.max  <> 9999.9
         AND g.min  IS NOT NULL AND g.min  <> 9999.9
        THEN 1 ELSE 0
      END
    ) AS good_days
  FROM `bigquery-public-data.noaa_gsod.gsod2022` AS g
  JOIN `bigquery-public-data.noaa_gsod.stations` AS s
    ON g.stn = s.usaf
  WHERE s.usaf <> '999999'           -- exclude dummy/invalid station codes
  GROUP BY g.stn
)

SELECT
  ROUND(
    100 * SUM(CASE WHEN good_days / total_days >= 0.9 THEN 1 END)
        / COUNT(*)
  , 2) AS pct_stations_90pct_good_2022
FROM per_station;