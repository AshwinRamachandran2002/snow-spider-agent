-- Weather stations within 20 mi of Chappaqua, NY and their
-- count of valid (temp ≠ 9999.9) observations for 2011-2020
WITH near_stations AS (
  SELECT
    usaf,
    wban,
    name,
    lat,
    lon
  FROM `bigquery-public-data.noaa_gsod.stations`
  WHERE ST_DWITHIN(
          ST_GEOGPOINT(lon, lat),          -- station location
          ST_GEOGPOINT(-73.764, 41.197),   -- Chappaqua, NY
          32186.8                          -- 20 miles in metres
        )
),
temp_counts AS (
  SELECT
    stn  AS usaf,
    wban,
    COUNT(*) AS valid_temp_obs
  FROM `bigquery-public-data.noaa_gsod.gsod*`
  WHERE _TABLE_SUFFIX BETWEEN '2011' AND '2020'
    AND temp <> 9999.9                    -- exclude missing temps
  GROUP BY usaf, wban
)
SELECT
  s.usaf,
  s.wban,
  s.name,
  s.lat,
  s.lon,
  COALESCE(t.valid_temp_obs, 0) AS valid_temp_obs_2011_2020
FROM near_stations AS s
LEFT JOIN temp_counts AS t USING (usaf, wban)
ORDER BY valid_temp_obs_2011_2020 DESC;