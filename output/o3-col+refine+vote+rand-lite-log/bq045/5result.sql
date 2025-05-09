WITH rainy_2023 AS (
  SELECT
    stn,
    wban,
    COUNTIF(prcp > 0 AND prcp != 99.99) AS rainy_days_2023
  FROM `bigquery-public-data.noaa_gsod.gsod2023`
  GROUP BY stn, wban
),
rainy_2022 AS (
  SELECT
    stn,
    wban,
    COUNTIF(prcp > 0 AND prcp != 99.99) AS rainy_days_2022
  FROM `bigquery-public-data.noaa_gsod.gsod2022`
  GROUP BY stn, wban
)
SELECT
  TRIM(s.name)            AS station_name,
  r23.stn,
  r23.wban,
  r23.rainy_days_2023,
  r22.rainy_days_2022
FROM rainy_2023 AS r23
JOIN rainy_2022 AS r22 USING (stn, wban)
JOIN `bigquery-public-data.noaa_gsod.stations` AS s
  ON s.usaf = r23.stn AND s.wban = r23.wban
WHERE s.state = 'WA'
  AND r23.rainy_days_2023 > 150           -- more than 150 rainy days in 2023
  AND r23.rainy_days_2023 < r22.rainy_days_2022   -- but fewer than in 2022
ORDER BY station_name;