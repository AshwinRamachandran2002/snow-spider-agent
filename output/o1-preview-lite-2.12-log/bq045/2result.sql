SELECT
  stations.usaf AS station_usaf,
  stations.wban AS station_wban,
  stations.name AS station_name
FROM
  (
    SELECT stn, wban, COUNT(*) AS rainy_days_2023
    FROM `bigquery-public-data.noaa_gsod.gsod2023`
    WHERE prcp != 99.99 AND prcp * 25.4 > 0
    GROUP BY stn, wban
  ) AS t2023
JOIN
  (
    SELECT stn, wban, COUNT(*) AS rainy_days_2022
    FROM `bigquery-public-data.noaa_gsod.gsod2022`
    WHERE prcp != 99.99 AND prcp * 25.4 > 0
    GROUP BY stn, wban
  ) AS t2022
ON t2023.stn = t2022.stn AND t2023.wban = t2022.wban
JOIN `bigquery-public-data.noaa_gsod.stations` AS stations
ON t2023.stn = stations.usaf AND t2023.wban = stations.wban
WHERE
  stations.state = 'WA'
  AND t2023.rainy_days_2023 > 150
  AND t2023.rainy_days_2023 < t2022.rainy_days_2022