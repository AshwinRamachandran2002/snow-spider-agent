/*  Weather stations in Washington (state = 'WA') that
    • recorded >150 rainy days in 2023
    • recorded fewer rainy days in 2023 than in 2022
    (rainy day: PRCP > 0 mm and PRCP ≠ 99.99) */

WITH
-- 2022 rainy‑day counts per station
rainy_2022 AS (
  SELECT
    stn            AS usaf,
    COUNT(*)       AS rainy_2022
  FROM `bigquery-public-data.noaa_gsod.gsod2022`
  WHERE prcp IS NOT NULL
    AND prcp != 99.99
    AND prcp > 0
  GROUP BY stn
),

-- 2023 rainy‑day counts per station
rainy_2023 AS (
  SELECT
    stn            AS usaf,
    COUNT(*)       AS rainy_2023
  FROM `bigquery-public-data.noaa_gsod.gsod2023`
  WHERE prcp IS NOT NULL
    AND prcp != 99.99
    AND prcp > 0
  GROUP BY stn
),

-- Washington‑state stations
wa_stations AS (
  SELECT
    usaf,
    TRIM(name) AS station_name
  FROM `bigquery-public-data.noaa_gsod.stations`
  WHERE state = 'WA'
)

SELECT
  w.usaf               AS station_id,
  w.station_name,
  r23.rainy_2023,
  r22.rainy_2022
FROM wa_stations w
JOIN rainy_2023 r23 USING (usaf)
JOIN rainy_2022 r22 USING (usaf)
WHERE r23.rainy_2023 > 150
  AND r23.rainy_2023 < r22.rainy_2022
ORDER BY r23.rainy_2023 DESC, w.usaf;