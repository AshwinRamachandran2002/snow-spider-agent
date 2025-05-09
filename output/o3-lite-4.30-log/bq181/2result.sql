WITH station_validity AS (
  SELECT
    g.stn AS usaf,
    COUNT(*) AS total_days,
    COUNTIF(
      g.temp IS NOT NULL  AND g.temp != 9999.9 AND
      g.max  IS NOT NULL  AND g.max  != 9999.9 AND
      g.min  IS NOT NULL  AND g.min  != 9999.9
    ) AS valid_days
  FROM `bigquery-public-data.noaa_gsod.gsod2022` AS g
  JOIN `bigquery-public-data.noaa_gsod.stations` AS s
    ON g.stn = s.usaf
  WHERE s.usaf != '999999'
  GROUP BY usaf
),
counts AS (
  SELECT
    COUNTIF(SAFE_DIVIDE(valid_days, total_days) >= 0.90) AS good_stations,
    (SELECT COUNT(DISTINCT usaf)
     FROM `bigquery-public-data.noaa_gsod.stations`
     WHERE usaf != '999999') AS all_stations
  FROM station_validity
)
SELECT
  ROUND(SAFE_DIVIDE(good_stations, all_stations) * 100, 4) AS percentage_valid_stations
FROM counts;