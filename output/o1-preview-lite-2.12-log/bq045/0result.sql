WITH rainy_days_2023 AS (
  SELECT
    gsod2023.stn,
    gsod2023.wban,
    COUNT(*) AS rainy_days_2023
  FROM
    `bigquery-public-data.noaa_gsod.gsod2023` AS gsod2023
  JOIN
    `bigquery-public-data.noaa_gsod.stations` AS stations
    ON gsod2023.stn = stations.usaf AND gsod2023.wban = stations.wban
  WHERE
    stations.state = 'WA'
    AND gsod2023.prcp > 0
    AND gsod2023.prcp != 99.99
  GROUP BY
    gsod2023.stn,
    gsod2023.wban
),
rainy_days_2022 AS (
  SELECT
    gsod2022.stn,
    gsod2022.wban,
    COUNT(*) AS rainy_days_2022
  FROM
    `bigquery-public-data.noaa_gsod.gsod2022` AS gsod2022
  JOIN
    `bigquery-public-data.noaa_gsod.stations` AS stations
    ON gsod2022.stn = stations.usaf AND gsod2022.wban = stations.wban
  WHERE
    stations.state = 'WA'
    AND gsod2022.prcp > 0
    AND gsod2022.prcp != 99.99
  GROUP BY
    gsod2022.stn,
    gsod2022.wban
)
SELECT
  rd2023.stn AS station_usaf,
  rd2023.wban AS station_wban,
  stations.name AS station_name
FROM
  rainy_days_2023 rd2023
JOIN
  rainy_days_2022 rd2022
  ON rd2023.stn = rd2022.stn AND rd2023.wban = rd2022.wban
JOIN
  `bigquery-public-data.noaa_gsod.stations` AS stations
  ON rd2023.stn = stations.usaf AND rd2023.wban = stations.wban
WHERE
  rd2023.rainy_days_2023 > 150
  AND rd2023.rainy_days_2023 < rd2022.rainy_days_2022
;