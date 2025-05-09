SELECT
  stations.name AS station_name,
  CONCAT(stations.usaf, '-', stations.wban) AS station_id,
  rd2023.rainy_days_2023,
  rd2022.rainy_days_2022
FROM
  `bigquery-public-data.noaa_gsod.stations` AS stations
JOIN
  (
    SELECT
      stn,
      wban,
      COUNTIF(prcp > 0 AND prcp != 99.99) AS rainy_days_2023
    FROM
      `bigquery-public-data.noaa_gsod.gsod2023`
    GROUP BY
      stn,
      wban
  ) AS rd2023
ON
  stations.usaf = rd2023.stn
  AND stations.wban = rd2023.wban
JOIN
  (
    SELECT
      stn,
      wban,
      COUNTIF(prcp > 0 AND prcp != 99.99) AS rainy_days_2022
    FROM
      `bigquery-public-data.noaa_gsod.gsod2022`
    GROUP BY
      stn,
      wban
  ) AS rd2022
ON
  stations.usaf = rd2022.stn
  AND stations.wban = rd2022.wban
WHERE
  stations.state = 'WA'
  AND rd2023.rainy_days_2023 > 150
  AND rd2023.rainy_days_2023 < rd2022.rainy_days_2022
ORDER BY
  rd2023.rainy_days_2023 DESC
;