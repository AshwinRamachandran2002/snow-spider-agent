-- Weather stations in Washington (WA) with >150 rainy days in 2023
-- but a lower rainy–day count than in 2022.
-- “Rainy day” = precipitation > 0 mm AND prcp <> 99.99 (missing code).

WITH rain_2023 AS (
  SELECT
    g.stn,
    g.wban,
    COUNTIF(g.prcp > 0 AND g.prcp <> 99.99) AS rainy_2023
  FROM `bigquery-public-data.noaa_gsod.gsod2023` AS g
  JOIN `bigquery-public-data.noaa_gsod.stations` AS s
    ON g.stn = s.usaf
   AND g.wban = s.wban
  WHERE s.state = 'WA'          -- Washington stations only
  GROUP BY g.stn, g.wban
),
rain_2022 AS (
  SELECT
    g.stn,
    g.wban,
    COUNTIF(g.prcp > 0 AND g.prcp <> 99.99) AS rainy_2022
  FROM `bigquery-public-data.noaa_gsod.gsod2022` AS g
  JOIN `bigquery-public-data.noaa_gsod.stations` AS s
    ON g.stn = s.usaf
   AND g.wban = s.wban
  WHERE s.state = 'WA'
  GROUP BY g.stn, g.wban
)

SELECT
  r23.stn,
  r23.wban,
  s.name                AS station_name,
  r23.rainy_2023,
  r22.rainy_2022
FROM rain_2023 AS r23
JOIN rain_2022 AS r22
  ON r23.stn  = r22.stn
 AND r23.wban = r22.wban
JOIN `bigquery-public-data.noaa_gsod.stations` AS s
  ON r23.stn  = s.usaf
 AND r23.wban = s.wban
WHERE r23.rainy_2023 > 150          -- more than 150 rainy days in 2023
  AND r23.rainy_2023 < r22.rainy_2022 -- but fewer than in 2022
ORDER BY r23.rainy_2023 DESC;