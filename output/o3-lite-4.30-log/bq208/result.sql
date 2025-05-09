WITH decade AS (
  SELECT stn, wban, temp FROM `bigquery-public-data.noaa_gsod.gsod2011`
  UNION ALL SELECT stn, wban, temp FROM `bigquery-public-data.noaa_gsod.gsod2012`
  UNION ALL SELECT stn, wban, temp FROM `bigquery-public-data.noaa_gsod.gsod2013`
  UNION ALL SELECT stn, wban, temp FROM `bigquery-public-data.noaa_gsod.gsod2014`
  UNION ALL SELECT stn, wban, temp FROM `bigquery-public-data.noaa_gsod.gsod2015`
  UNION ALL SELECT stn, wban, temp FROM `bigquery-public-data.noaa_gsod.gsod2016`
  UNION ALL SELECT stn, wban, temp FROM `bigquery-public-data.noaa_gsod.gsod2017`
  UNION ALL SELECT stn, wban, temp FROM `bigquery-public-data.noaa_gsod.gsod2018`
  UNION ALL SELECT stn, wban, temp FROM `bigquery-public-data.noaa_gsod.gsod2019`
  UNION ALL SELECT stn, wban, temp FROM `bigquery-public-data.noaa_gsod.gsod2020`
)

SELECT
  CONCAT(s.usaf,'-',s.wban)                                             AS station_id,
  FORMAT('(%0.4f, %0.4f)', s.lat, s.lon)                                AS station_coordinates,
  COUNT(*)                                                              AS valid_temperature_observations_2011_2020
FROM decade AS d
JOIN `bigquery-public-data.noaa_gsod.stations` AS s
  ON d.stn  = s.usaf
 AND d.wban = s.wban
WHERE d.temp != 9999.9
  AND ST_DWITHIN(
        ST_GEOGPOINT(s.lon, s.lat),
        ST_GEOGPOINT(-73.764, 41.197),      -- Chappaqua, NY
        32186.88                            -- 20 miles in metres
      )
GROUP BY station_id, station_coordinates
ORDER BY valid_temperature_observations_2011_2020 DESC;