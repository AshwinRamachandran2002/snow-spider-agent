WITH rainy_2023 AS (
  SELECT
    stn  AS usaf,
    wban,
    COUNTIF(prcp IS NOT NULL            -- value present
            AND prcp != 99.99           -- valid (not missing code)
            AND prcp > 0)               -- truly rainy
        AS rainy_days_2023
  FROM `bigquery-public-data.noaa_gsod.gsod2023`
  GROUP BY usaf, wban
),
rainy_2022 AS (
  SELECT
    stn  AS usaf,
    wban,
    COUNTIF(prcp IS NOT NULL
            AND prcp != 99.99
            AND prcp > 0)
        AS rainy_days_2022
  FROM `bigquery-public-data.noaa_gsod.gsod2022`
  GROUP BY usaf, wban
)
SELECT
  s.usaf,
  s.wban,
  TRIM(s.name)            AS station_name,
  r23.rainy_days_2023,
  r22.rainy_days_2022
FROM rainy_2023 r23
JOIN rainy_2022 r22 USING (usaf, wban)
JOIN `bigquery-public-data.noaa_gsod.stations` s
     ON s.usaf = r23.usaf
    AND s.wban = r23.wban
WHERE s.country = 'US'
  AND s.state   = 'WA'                  -- Washington State
  AND r23.rainy_days_2023 > 150         -- >150 rainy days in 2023
  AND r23.rainy_days_2023 < r22.rainy_days_2022  -- fewer than in 2022
ORDER BY r23.rainy_days_2023 DESC, s.usaf, s.wban;