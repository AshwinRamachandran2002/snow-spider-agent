-- Stations in Washington (WA) with >150 rainy days in 2023
-- but fewer rainy days than in 2022.
-- A “rainy day” = PRCP > 0  AND PRCP ≠ 99.99 (valid, non‑missing).

WITH station_wa AS (
  SELECT
    usaf,
    wban,
    TRIM(name) AS station_name
  FROM `bigquery-public-data.noaa_gsod.stations`
  WHERE state = 'WA'            -- Washington State only
),

rain_2022 AS (
  SELECT
    g.stn  AS usaf,
    g.wban,
    COUNTIF(g.prcp > 0 AND g.prcp <> 99.99) AS rainy_days_2022
  FROM `bigquery-public-data.noaa_gsod.gsod2022` AS g
  JOIN station_wa AS s
    ON g.stn  = s.usaf
   AND g.wban = s.wban
  GROUP BY usaf, g.wban
),

rain_2023 AS (
  SELECT
    g.stn  AS usaf,
    g.wban,
    COUNTIF(g.prcp > 0 AND g.prcp <> 99.99) AS rainy_days_2023
  FROM `bigquery-public-data.noaa_gsod.gsod2023` AS g
  JOIN station_wa AS s
    ON g.stn  = s.usaf
   AND g.wban = s.wban
  GROUP BY usaf, g.wban
)

SELECT
  s.station_name,
  s.usaf,
  s.wban,
  r23.rainy_days_2023,
  r22.rainy_days_2022
FROM rain_2023 AS r23
JOIN rain_2022 AS r22
  USING (usaf, wban)
JOIN station_wa AS s
  USING (usaf, wban)
WHERE r23.rainy_days_2023 > 150              -- more than 150 rainy days in 2023
  AND r23.rainy_days_2023 < r22.rainy_days_2022   -- but fewer than in 2022
ORDER BY r23.rainy_days_2023 DESC, s.station_name;