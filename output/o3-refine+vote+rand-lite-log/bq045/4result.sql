-- Weather stations in Washington (WA) that 
-- • had >150 “rainy days” in 2023 (prcp > 0 and ≠ 99.99)  
-- • but recorded fewer such days than in 2022

WITH rainy_2022 AS (
  SELECT
    stn,
    wban,
    COUNTIF(prcp > 0 AND prcp != 99.99) AS rainy_2022
  FROM `bigquery-public-data.noaa_gsod.gsod2022`
  WHERE prcp != 99.99                                  -- keep only valid precip values
  GROUP BY stn, wban
),
rainy_2023 AS (
  SELECT
    stn,
    wban,
    COUNTIF(prcp > 0 AND prcp != 99.99) AS rainy_2023
  FROM `bigquery-public-data.noaa_gsod.gsod2023`
  WHERE prcp != 99.99
  GROUP BY stn, wban
),
combined AS (
  SELECT
    r23.stn,
    r23.wban,
    r23.rainy_2023,
    r22.rainy_2022
  FROM rainy_2023 r23
  JOIN rainy_2022 r22
    ON r23.stn  = r22.stn
   AND r23.wban = r22.wban
)
SELECT
  c.stn   AS usaf,
  c.wban,
  s.name  AS station_name,
  c.rainy_2023,
  c.rainy_2022
FROM combined c
JOIN `bigquery-public-data.noaa_gsod.stations` s
  ON c.stn  = s.usaf
 AND c.wban = s.wban
WHERE s.country = 'US'
  AND s.state   = 'WA'         -- Washington State
  AND c.rainy_2023 > 150
  AND c.rainy_2023 < c.rainy_2022
ORDER BY c.rainy_2023 DESC;