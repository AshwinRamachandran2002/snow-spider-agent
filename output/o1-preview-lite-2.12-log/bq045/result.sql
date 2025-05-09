WITH wa_stations AS (
  SELECT usaf, wban, name
  FROM `bigquery-public-data.noaa_gsod.stations`
  WHERE state = 'WA'
),
rainy_days_2022 AS (
  SELECT
    g.stn,
    g.wban,
    COUNTIF(g.prcp > 0 AND g.prcp != 99.99) AS rainy_days_2022
  FROM `bigquery-public-data.noaa_gsod.gsod2022` AS g
  JOIN wa_stations AS s
  ON g.stn = s.usaf AND g.wban = s.wban
  WHERE g.prcp IS NOT NULL
  GROUP BY g.stn, g.wban
),
rainy_days_2023 AS (
  SELECT
    g.stn,
    g.wban,
    COUNTIF(g.prcp > 0 AND g.prcp != 99.99) AS rainy_days_2023
  FROM `bigquery-public-data.noaa_gsod.gsod2023` AS g
  JOIN wa_stations AS s
  ON g.stn = s.usaf AND g.wban = s.wban
  WHERE g.prcp IS NOT NULL
  GROUP BY g.stn, g.wban
)
SELECT
  s.usaf AS station_usaf,
  s.wban AS station_wban,
  s.name AS station_name
FROM wa_stations AS s
JOIN rainy_days_2023 AS rd2023 ON s.usaf = rd2023.stn AND s.wban = rd2023.wban
JOIN rainy_days_2022 AS rd2022 ON s.usaf = rd2022.stn AND s.wban = rd2022.wban
WHERE rd2023.rainy_days_2023 > 150
  AND rd2023.rainy_days_2023 < rd2022.rainy_days_2022;