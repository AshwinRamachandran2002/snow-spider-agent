SELECT
  s.name AS station_name,
  CONCAT(gsod2023.stn, '-', gsod2023.wban) AS station_id,
  gsod2023.rainy_days_2023,
  gsod2022.rainy_days_2022
FROM
  (
    SELECT gsod.stn, gsod.wban, COUNTIF(gsod.prcp > 0.00) AS rainy_days_2023
    FROM `bigquery-public-data.noaa_gsod.gsod2023` AS gsod
    JOIN `bigquery-public-data.noaa_gsod.stations` AS s
      ON gsod.stn = s.usaf AND gsod.wban = s.wban
    WHERE s.state = 'WA' AND gsod.prcp != 99.99
    GROUP BY gsod.stn, gsod.wban
  ) AS gsod2023
JOIN
  (
    SELECT gsod.stn, gsod.wban, COUNTIF(gsod.prcp > 0.00) AS rainy_days_2022
    FROM `bigquery-public-data.noaa_gsod.gsod2022` AS gsod
    JOIN `bigquery-public-data.noaa_gsod.stations` AS s
      ON gsod.stn = s.usaf AND gsod.wban = s.wban
    WHERE s.state = 'WA' AND gsod.prcp != 99.99
    GROUP BY gsod.stn, gsod.wban
  ) AS gsod2022
  ON gsod2023.stn = gsod2022.stn AND gsod2023.wban = gsod2022.wban
JOIN `bigquery-public-data.noaa_gsod.stations` AS s
  ON gsod2023.stn = s.usaf AND gsod2023.wban = s.wban
WHERE gsod2023.rainy_days_2023 > 150 AND gsod2023.rainy_days_2023 < gsod2022.rainy_days_2022
ORDER BY gsod2023.rainy_days_2023 DESC;