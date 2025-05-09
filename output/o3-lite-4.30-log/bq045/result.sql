WITH rainy_2022 AS (
  SELECT
    g.stn,
    g.wban,
    COUNTIF(g.prcp > 0 AND g.prcp != 99.99) AS rainy_days_2022
  FROM `bigquery-public-data.noaa_gsod.gsod2022` g
  JOIN `bigquery-public-data.noaa_gsod.stations` s
    ON s.usaf = g.stn AND s.wban = g.wban
  WHERE s.state = 'WA'
  GROUP BY g.stn, g.wban
),
rainy_2023 AS (
  SELECT
    g.stn,
    g.wban,
    COUNTIF(g.prcp > 0 AND g.prcp != 99.99) AS rainy_days_2023
  FROM `bigquery-public-data.noaa_gsod.gsod2023` g
  JOIN `bigquery-public-data.noaa_gsod.stations` s
    ON s.usaf = g.stn AND s.wban = g.wban
  WHERE s.state = 'WA'
  GROUP BY g.stn, g.wban
)
SELECT
  CONCAT(r23.stn, '-', r23.wban) AS station_id,
  TRIM(s.name)                  AS station_name,
  ROUND(s.lat, 4)               AS latitude,
  ROUND(s.lon, 4)               AS longitude,
  r22.rainy_days_2022,
  r23.rainy_days_2023
FROM rainy_2023 AS r23
JOIN rainy_2022 AS r22 USING (stn, wban)
JOIN `bigquery-public-data.noaa_gsod.stations` s
  ON s.usaf = r23.stn AND s.wban = r23.wban
WHERE r23.rainy_days_2023 > 150
  AND r23.rainy_days_2023 < r22.rainy_days_2022
ORDER BY r23.rainy_days_2023 DESC;