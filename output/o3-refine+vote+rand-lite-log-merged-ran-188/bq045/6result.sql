WITH rainy_2023 AS (
  SELECT
    g.stn AS usaf,
    g.wban,
    COUNTIF(g.prcp > 0 AND g.prcp != 99.99) AS rainy_days_2023
  FROM `bigquery-public-data.noaa_gsod.gsod2023` AS g
  JOIN `bigquery-public-data.noaa_gsod.stations` AS s
    ON g.stn = s.usaf AND g.wban = s.wban
  WHERE s.country = 'US'
    AND s.state = 'WA'                -- Washington State
  GROUP BY usaf, g.wban
),
rainy_2022 AS (
  SELECT
    g.stn AS usaf,
    g.wban,
    COUNTIF(g.prcp > 0 AND g.prcp != 99.99) AS rainy_days_2022
  FROM `bigquery-public-data.noaa_gsod.gsod2022` AS g
  JOIN `bigquery-public-data.noaa_gsod.stations` AS s
    ON g.stn = s.usaf AND g.wban = s.wban
  WHERE s.country = 'US'
    AND s.state = 'WA'                -- Washington State
  GROUP BY usaf, g.wban
)

SELECT
  r23.usaf,
  r23.wban,
  s.name                        AS station_name,
  s.lat                         AS latitude,
  s.lon                         AS longitude,
  r23.rainy_days_2023,
  r22.rainy_days_2022
FROM rainy_2023 AS r23
JOIN rainy_2022 AS r22
  ON r23.usaf = r22.usaf AND r23.wban = r22.wban
JOIN `bigquery-public-data.noaa_gsod.stations` AS s
  ON r23.usaf = s.usaf AND r23.wban = s.wban
WHERE r23.rainy_days_2023 > 150          -- more than 150 rainy days in 2023
  AND r23.rainy_days_2023 < r22.rainy_days_2022   -- but fewer than in 2022
ORDER BY r23.rainy_days_2023 DESC, r23.usaf, r23.wban;