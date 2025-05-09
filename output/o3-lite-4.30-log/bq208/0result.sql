WITH stations_near AS (
  SELECT
    usaf,
    wban,
    FORMAT('%.4f,%.4f', lat, lon) AS station_coordinates
  FROM `bigquery-public-data.noaa_gsod.stations`
  WHERE lat IS NOT NULL
    AND lon IS NOT NULL
    AND ST_DWITHIN(
          ST_GEOGPOINT(lon, lat),
          ST_GEOGPOINT(-73.764, 41.197),   -- Chappaqua, NY
          32186.88                         -- 20‑mile radius (meters)
        )
),
gsod_2011_2020 AS (
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
),
valid_counts AS (
  SELECT
    stn AS usaf,
    wban,
    COUNT(*) AS valid_temperature_observations_2011_2020
  FROM gsod_2011_2020
  WHERE temp <> 9999.9                         -- exclude invalid/missing temperatures
  GROUP BY usaf, wban
)
SELECT
  CONCAT(s.usaf, '-', s.wban) AS station_id,
  s.station_coordinates,
  COALESCE(v.valid_temperature_observations_2011_2020, 0) AS valid_temperature_observations_2011_2020
FROM stations_near AS s
LEFT JOIN valid_counts AS v
  ON v.usaf = s.usaf
 AND v.wban = s.wban
ORDER BY
  valid_temperature_observations_2011_2020 DESC,
  station_id