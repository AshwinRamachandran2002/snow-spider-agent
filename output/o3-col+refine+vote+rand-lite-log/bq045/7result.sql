-- Weather stations in Washington (WA) with >150 rainy days in 2023
-- but fewer rainy days in 2022.
-- A “rainy day” here is defined as PRCP > 0 and PRCP <> 99.99.

WITH wa_stations AS (
  SELECT
    usaf AS stn,
    wban,
    name
  FROM `bigquery-public-data.noaa_gsod.stations`
  WHERE state = 'WA'
),

rainy_2023 AS (
  SELECT
    g.stn,
    g.wban,
    COUNTIF(g.prcp > 0 AND g.prcp <> 99.99) AS rainy_days_2023
  FROM `bigquery-public-data.noaa_gsod.gsod2023` AS g
  JOIN wa_stations s
    ON g.stn = s.stn AND g.wban = s.wban
  GROUP BY g.stn, g.wban
),

rainy_2022 AS (
  SELECT
    g.stn,
    g.wban,
    COUNTIF(g.prcp > 0 AND g.prcp <> 99.99) AS rainy_days_2022
  FROM `bigquery-public-data.noaa_gsod.gsod2022` AS g
  JOIN wa_stations s
    ON g.stn = s.stn AND g.wban = s.wban
  GROUP BY g.stn, g.wban
)

SELECT
  r23.stn,
  r23.wban,
  s.name AS station_name,
  r23.rainy_days_2023,
  r22.rainy_days_2022
FROM rainy_2023 r23
JOIN rainy_2022 r22 USING (stn, wban)
JOIN wa_stations s USING (stn, wban)
WHERE r23.rainy_days_2023 > 150
  AND r22.rainy_days_2022 < r23.rainy_days_2023
ORDER BY r23.rainy_days_2023 DESC;