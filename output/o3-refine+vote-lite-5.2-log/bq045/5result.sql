-- Weather stations in Washington (WA) that had
--  • more than 150 “rainy days” (prcp > 0 mm and ≠ 99.99) in 2023
--  • but fewer rainy days in 2023 than in 2022
--
WITH
-- 2022 rainy‑day counts per station
rain_2022 AS (
  SELECT
    stn,
    wban,
    COUNTIF(prcp IS NOT NULL
            AND prcp != 99.99
            AND prcp > 0) AS rainy_2022
  FROM `bigquery-public-data.noaa_gsod.gsod2022`
  GROUP BY stn, wban
),
-- 2023 rainy‑day counts per station
rain_2023 AS (
  SELECT
    stn,
    wban,
    COUNTIF(prcp IS NOT NULL
            AND prcp != 99.99
            AND prcp > 0) AS rainy_2023
  FROM `bigquery-public-data.noaa_gsod.gsod2023`
  GROUP BY stn, wban
),
-- Washington‑state stations
wa_stations AS (
  SELECT
    TRIM(name)          AS station_name,
    usaf                AS stn,
    wban,
    state
  FROM `bigquery-public-data.noaa_gsod.stations`
  WHERE state = 'WA'
),
-- Combine counts with station metadata
combined AS (
  SELECT
    ws.station_name,
    ws.stn,
    ws.wban,
    r22.rainy_2022,
    r23.rainy_2023
  FROM wa_stations ws
  JOIN rain_2022 r22 USING (stn, wban)
  JOIN rain_2023 r23 USING (stn, wban)
)
SELECT
  station_name,
  stn  AS usaf_code,
  wban,
  rainy_2023,
  rainy_2022
FROM combined
WHERE rainy_2023 > 150
  AND rainy_2023 < rainy_2022
ORDER BY rainy_2023 DESC, station_name;