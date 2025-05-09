-- Weather stations within 20 miles (≈32,186.88 m) of Chappaqua, NY
-- and the number of valid (≠ 9999.9) temperature observations
-- recorded between 2011 and 2020.
WITH station_subset AS (
  SELECT
    usaf,
    wban,
    name,
    lat,
    lon
  FROM `bigquery-public-data.noaa_gsod.stations`
  WHERE
    lat IS NOT NULL
    AND lon IS NOT NULL
    AND ST_DWITHIN(
          ST_GEOGPOINT(lon, lat),               -- station location
          ST_GEOGPOINT(-73.764, 41.197),        -- Chappaqua, NY
          32186.88                              -- 20 miles in meters
        )
),
valid_temps AS (
  SELECT
    stn,
    wban,
    COUNT(*) AS temp_count
  FROM `bigquery-public-data.noaa_gsod.gsod20*`
  WHERE
    _TABLE_SUFFIX BETWEEN '11' AND '20'    -- tables gsod2011 … gsod2020
    AND year BETWEEN '2011' AND '2020'     -- safety check
    AND temp <> 9999.9                     -- exclude missing/invalid temps
  GROUP BY stn, wban
)

SELECT
  s.name,
  s.usaf,
  s.wban,
  s.lat  AS latitude,
  s.lon  AS longitude,
  COALESCE(v.temp_count, 0) AS valid_temperature_observations_2011_2020
FROM station_subset AS s
LEFT JOIN valid_temps AS v
  ON v.stn = s.usaf
 AND v.wban = s.wban
ORDER BY valid_temperature_observations_2011_2020 DESC,
         s.name;