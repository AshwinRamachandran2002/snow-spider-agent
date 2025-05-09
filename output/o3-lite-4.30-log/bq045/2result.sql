WITH rainy_2023 AS (
  SELECT
    g.stn,
    g.wban,
    COUNTIF(g.prcp > 0 AND g.prcp != 99.99) AS rainy_days_2023
  FROM `bigquery-public-data.noaa_gsod.gsod2023` AS g
  JOIN `bigquery-public-data.noaa_gsod.stations` AS s
    ON g.stn = s.usaf AND g.wban = s.wban
  WHERE s.country = 'US'
    AND s.state   = 'WA'
  GROUP BY g.stn, g.wban
),
rainy_2022 AS (
  SELECT
    g.stn,
    g.wban,
    COUNTIF(g.prcp > 0 AND g.prcp != 99.99) AS rainy_days_2022
  FROM `bigquery-public-data.noaa_gsod.gsod2022` AS g
  JOIN `bigquery-public-data.noaa_gsod.stations` AS s
    ON g.stn = s.usaf AND g.wban = s.wban
  WHERE s.country = 'US'
    AND s.state   = 'WA'
  GROUP BY g.stn, g.wban
)
SELECT
  CONCAT(r23.stn, '-', r23.wban)           AS station_id,
  TRIM(s.name)                             AS station_name,
  ROUND(s.lat, 4)                          AS latitude,
  ROUND(s.lon, 4)                          AS longitude,
  r22.rainy_days_2022,
  r23.rainy_days_2023
FROM rainy_2023 AS r23
JOIN rainy_2022 AS r22
  ON r23.stn = r22.stn AND r23.wban = r22.wban
JOIN `bigquery-public-data.noaa_gsod.stations` AS s
  ON r23.stn = s.usaf AND r23.wban = s.wban
WHERE r23.rainy_days_2023 > 150
  AND r23.rainy_days_2023 < r22.rainy_days_2022
ORDER BY r23.rainy_days_2023 DESC, station_id;