-- WA stations with >150 “rainy days” (prcp >0 & ≠ 99.99) in 2023
-- but FEWER rainy days than they had in 2022
WITH rain_2023 AS (
  SELECT
    g.stn,
    g.wban,
    COUNT(*) AS rainy_2023
  FROM `bigquery-public-data.noaa_gsod.gsod2023` AS g
  JOIN `bigquery-public-data.noaa_gsod.stations` AS s
    ON g.stn  = s.usaf
   AND g.wban = s.wban
  WHERE s.country = 'US'
    AND s.state   = 'WA'
    AND g.prcp    < 99.99    -- valid daily value
    AND g.prcp    > 0        -- actually rained
  GROUP BY g.stn, g.wban
),
rain_2022 AS (
  SELECT
    g.stn,
    g.wban,
    COUNT(*) AS rainy_2022
  FROM `bigquery-public-data.noaa_gsod.gsod2022` AS g
  JOIN `bigquery-public-data.noaa_gsod.stations` AS s
    ON g.stn  = s.usaf
   AND g.wban = s.wban
  WHERE s.country = 'US'
    AND s.state   = 'WA'
    AND g.prcp    < 99.99
    AND g.prcp    > 0
  GROUP BY g.stn, g.wban
)
SELECT
  s.usaf  AS station_usaf,
  s.wban,
  s.name  AS station_name,
  r23.rainy_2023,
  r22.rainy_2022
FROM rain_2023 AS r23
JOIN rain_2022 AS r22
  ON r23.stn = r22.stn
 AND r23.wban = r22.wban
JOIN `bigquery-public-data.noaa_gsod.stations` AS s
  ON s.usaf = r23.stn
 AND s.wban = r23.wban
WHERE r23.rainy_2023 > 150       -- more than 150 rainy days in 2023
  AND r23.rainy_2023 < r22.rainy_2022  -- but fewer than in 2022
ORDER BY r23.rainy_2023 DESC;