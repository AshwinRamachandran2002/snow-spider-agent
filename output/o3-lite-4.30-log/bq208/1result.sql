WITH nearby_stations AS (
  SELECT
    usaf,
    wban,
    ROUND(lat, 4) AS lat4,
    ROUND(lon, 4) AS lon4
  FROM `bigquery-public-data.noaa_gsod.stations`
  WHERE ST_DWITHIN(
          ST_GEOGPOINT(lon, lat),
          ST_GEOGPOINT(-73.764, 41.197),      -- Chappaqua, NY
          32186.9                              -- 20 miles in metres
        )
),
obs_2011_2020 AS (
  SELECT stn, wban, temp FROM `bigquery-public-data.noaa_gsod.gsod2011` UNION ALL
  SELECT stn, wban, temp FROM `bigquery-public-data.noaa_gsod.gsod2012` UNION ALL
  SELECT stn, wban, temp FROM `bigquery-public-data.noaa_gsod.gsod2013` UNION ALL
  SELECT stn, wban, temp FROM `bigquery-public-data.noaa_gsod.gsod2014` UNION ALL
  SELECT stn, wban, temp FROM `bigquery-public-data.noaa_gsod.gsod2015` UNION ALL
  SELECT stn, wban, temp FROM `bigquery-public-data.noaa_gsod.gsod2016` UNION ALL
  SELECT stn, wban, temp FROM `bigquery-public-data.noaa_gsod.gsod2017` UNION ALL
  SELECT stn, wban, temp FROM `bigquery-public-data.noaa_gsod.gsod2018` UNION ALL
  SELECT stn, wban, temp FROM `bigquery-public-data.noaa_gsod.gsod2019` UNION ALL
  SELECT stn, wban, temp FROM `bigquery-public-data.noaa_gsod.gsod2020`
)

SELECT
  CONCAT(ns.usaf, '-', ns.wban) AS station_id,
  CONCAT('(',
         FORMAT('%.4f', ns.lat4), ', ',
         FORMAT('%.4f', ns.lon4), ')')        AS station_coordinates,
  COUNT(*)                                    AS valid_temperature_observations_2011_2020
FROM obs_2011_2020 AS o
JOIN nearby_stations AS ns
  ON o.stn  = ns.usaf
 AND o.wban = ns.wban
WHERE o.temp <> 9999.9
GROUP BY station_id, station_coordinates
ORDER BY valid_temperature_observations_2011_2020 DESC, station_id;