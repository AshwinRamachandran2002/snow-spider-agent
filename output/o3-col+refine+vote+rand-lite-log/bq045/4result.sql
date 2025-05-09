-- Washington stations with >150 rainy days in 2023 but fewer than in 2022
WITH wa_stations AS (                       -- all WA station IDs
  SELECT usaf
  FROM `bigquery-public-data.noaa_gsod.stations`
  WHERE state = 'WA'
),

rain_2022 AS (                              -- rainy-day counts for 2022
  SELECT
    stn AS usaf,
    COUNTIF(prcp > 0 AND prcp < 99.99) AS rainy_2022
  FROM `bigquery-public-data.noaa_gsod.gsod2022`
  WHERE stn IN (SELECT usaf FROM wa_stations)
  GROUP BY usaf
),

rain_2023 AS (                              -- rainy-day counts for 2023
  SELECT
    stn AS usaf,
    COUNTIF(prcp > 0 AND prcp < 99.99) AS rainy_2023
  FROM `bigquery-public-data.noaa_gsod.gsod2023`
  WHERE stn IN (SELECT usaf FROM wa_stations)
  GROUP BY usaf
)

SELECT
  r23.usaf,
  TRIM(s.name)                         AS station_name,
  r22.rainy_2022,
  r23.rainy_2023
FROM rain_2023 AS r23
JOIN rain_2022 AS r22 USING (usaf)
JOIN `bigquery-public-data.noaa_gsod.stations` AS s
  ON s.usaf = r23.usaf
WHERE r23.rainy_2023 > 150              -- >150 rainy days in 2023
  AND r23.rainy_2023 < r22.rainy_2022   -- but fewer than in 2022
ORDER BY station_name;