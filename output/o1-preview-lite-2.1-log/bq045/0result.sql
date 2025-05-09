SELECT
    s.name AS station_name,
    CONCAT(s.usaf, '-', s.wban) AS station_id,
    data2023.rainy_days_2023,
    data2022.rainy_days_2022
FROM
    (
        SELECT
            stn,
            wban,
            COUNTIF(prcp > 0 AND prcp != 99.99) AS rainy_days_2023
        FROM `bigquery-public-data.noaa_gsod.gsod2023`
        WHERE prcp IS NOT NULL
        GROUP BY stn, wban
    ) AS data2023
JOIN
    (
        SELECT
            stn,
            wban,
            COUNTIF(prcp > 0 AND prcp != 99.99) AS rainy_days_2022
        FROM `bigquery-public-data.noaa_gsod.gsod2022`
        WHERE prcp IS NOT NULL
        GROUP BY stn, wban
    ) AS data2022
ON data2023.stn = data2022.stn AND data2023.wban = data2022.wban
JOIN `bigquery-public-data.noaa_gsod.stations` AS s
ON data2023.stn = s.usaf AND data2023.wban = s.wban
WHERE s.state = 'WA'
  AND data2023.rainy_days_2023 > 150
  AND data2023.rainy_days_2023 < data2022.rainy_days_2022;