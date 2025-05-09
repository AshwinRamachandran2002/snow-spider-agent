/*  Weather stations in Washington (state = 'WA') that
    1) have valid precipitation data
    2) logged >150 rainy days (prcp > 0 mm and <> 99.99) in 2023
    3) logged fewer rainy days in 2023 than in 2022                                   */

WITH rainy_2022 AS (
  SELECT
    stn,
    wban,
    COUNT(1) AS rainy_days_2022
  FROM `bigquery-public-data.noaa_gsod.gsod2022`
  WHERE prcp IS NOT NULL            -- valid value present
    AND prcp != 99.99               -- exclude missing codes
    AND prcp > 0                    -- define a “rainy day”
  GROUP BY stn, wban
),
rainy_2023 AS (
  SELECT
    stn,
    wban,
    COUNT(1) AS rainy_days_2023
  FROM `bigquery-public-data.noaa_gsod.gsod2023`
  WHERE prcp IS NOT NULL
    AND prcp != 99.99
    AND prcp > 0
  GROUP BY stn, wban
),
wa_stations AS (
  SELECT
    usaf AS stn,
    wban,
    TRIM(name) AS station_name
  FROM `bigquery-public-data.noaa_gsod.stations`
  WHERE state = 'WA'                -- Washington State
)

SELECT
  s.station_name,
  s.stn,
  s.wban,
  r23.rainy_days_2023,
  r22.rainy_days_2022
FROM wa_stations        AS s
JOIN rainy_2023         AS r23 USING (stn, wban)
JOIN rainy_2022         AS r22 USING (stn, wban)
WHERE r23.rainy_days_2023 > 150           -- >150 rainy days in 2023
  AND r23.rainy_days_2023 < r22.rainy_days_2022  -- fewer than in 2022
ORDER BY r23.rainy_days_2023 DESC;