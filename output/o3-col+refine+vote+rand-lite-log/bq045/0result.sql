-- Weather stations in Washington (US-WA) that
-- (1) logged >150 rainy days in 2023 and
-- (2) had fewer rainy days in 2023 than in 2022
-- A rainy day = PRCP > 0 mm and PRCP ≠ 99.99 (missing-value flag)

WITH rainy_2023 AS (
  SELECT
    CONCAT(stn,'-',wban)              AS station_id,
    COUNTIF(prcp > 0 AND prcp <> 99.99) AS rainy_days_2023
  FROM `bigquery-public-data.noaa_gsod.gsod2023`
  GROUP BY station_id
),
rainy_2022 AS (
  SELECT
    CONCAT(stn,'-',wban)              AS station_id,
    COUNTIF(prcp > 0 AND prcp <> 99.99) AS rainy_days_2022
  FROM `bigquery-public-data.noaa_gsod.gsod2022`
  GROUP BY station_id
)

SELECT
  r23.station_id,
  TRIM(s.name)                        AS station_name,
  r23.rainy_days_2023,
  r22.rainy_days_2022
FROM rainy_2023 r23
JOIN rainy_2022 r22     ON r23.station_id = r22.station_id
JOIN `bigquery-public-data.noaa_gsod.stations` s
     ON r23.station_id = CONCAT(s.usaf,'-',s.wban)
WHERE s.state = 'WA'            -- Washington
  AND s.country = 'US'
  AND r23.rainy_days_2023 > 150
  AND r23.rainy_days_2023 < r22.rainy_days_2022
ORDER BY r23.rainy_days_2023 DESC;