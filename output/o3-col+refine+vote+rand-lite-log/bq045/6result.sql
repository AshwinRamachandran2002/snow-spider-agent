-- Weather-stations in Washington (state='WA') that  
-- had >150 rainy days in 2023 AND fewer rainy days than in 2022
WITH rainy_2022 AS (
  SELECT
    stn,
    wban,
    COUNTIF(prcp > 0 AND prcp != 99.99) AS rainy_2022
  FROM `bigquery-public-data.noaa_gsod.gsod2022`
  GROUP BY stn, wban
),
rainy_2023 AS (
  SELECT
    stn,
    wban,
    COUNTIF(prcp > 0 AND prcp != 99.99) AS rainy_2023
  FROM `bigquery-public-data.noaa_gsod.gsod2023`
  GROUP BY stn, wban
)
SELECT
  TRIM(s.name)             AS station_name,
  s.usaf                   AS stn,
  s.wban,
  r23.rainy_2023,
  r22.rainy_2022
FROM `bigquery-public-data.noaa_gsod.stations` AS s
JOIN rainy_2023 AS r23
  ON s.usaf = r23.stn  AND s.wban = r23.wban
JOIN rainy_2022 AS r22
  ON s.usaf = r22.stn  AND s.wban = r22.wban
WHERE
  s.state = 'WA'              -- Washington State stations
  AND r23.rainy_2023 > 150    -- >150 rainy days in 2023
  AND r23.rainy_2023 < r22.rainy_2022   -- fewer rainy days than in 2022
ORDER BY
  station_name;