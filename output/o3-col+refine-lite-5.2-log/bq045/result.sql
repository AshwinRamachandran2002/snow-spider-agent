-- Weather stations in Washington (WA) with >150 rainy days in 2023
-- but fewer rainy days than in 2022.
-- A “rainy day” is counted when PRCP > 0 AND PRCP != 99.99.

WITH rainy_2023 AS (     -- count rainy days for 2023
  SELECT
    g.stn,
    g.wban,
    COUNTIF(g.prcp > 0 AND g.prcp != 99.99) AS rainy_2023
  FROM `bigquery-public-data.noaa_gsod.gsod2023` AS g
  JOIN `bigquery-public-data.noaa_gsod.stations` AS s
    ON g.stn = s.usaf AND g.wban = s.wban
  WHERE s.state = 'WA'
  GROUP BY g.stn, g.wban
),
rainy_2022 AS (          -- count rainy days for 2022
  SELECT
    g.stn,
    g.wban,
    COUNTIF(g.prcp > 0 AND g.prcp != 99.99) AS rainy_2022
  FROM `bigquery-public-data.noaa_gsod.gsod2022` AS g
  JOIN `bigquery-public-data.noaa_gsod.stations` AS s
    ON g.stn = s.usaf AND g.wban = s.wban
  WHERE s.state = 'WA'
  GROUP BY g.stn, g.wban
)

SELECT
  r23.stn   AS usaf,
  r23.wban,
  s.name    AS station_name,
  r23.rainy_2023,
  r22.rainy_2022
FROM rainy_2023 AS r23
JOIN rainy_2022 AS r22 USING (stn, wban)
JOIN `bigquery-public-data.noaa_gsod.stations` AS s
  ON r23.stn = s.usaf AND r23.wban = s.wban
WHERE r23.rainy_2023 > 150        -- more than 150 rainy days in 2023
  AND r23.rainy_2023 < r22.rainy_2022  -- but fewer than in 2022
ORDER BY r23.rainy_2023 DESC, r23.stn;