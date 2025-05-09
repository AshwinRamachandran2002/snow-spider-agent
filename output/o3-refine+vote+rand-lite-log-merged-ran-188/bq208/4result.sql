-- Weather stations within 20‑mile (≈32 186.9 m) radius of Chappaqua, NY
-- together with the count of DAILY mean‑temperature observations
-- whose value is NOT the missing‑data flag (9999.9) for years 2011‑2020.
WITH target_stations AS (
  SELECT
    usaf,
    wban,
    TRIM(name)      AS station_name,
    lat,
    lon
  FROM `bigquery-public-data.noaa_gsod.stations`
  WHERE lat IS NOT NULL
    AND lon IS NOT NULL
    AND NOT (lat = 0 AND lon = 0)                     -- exclude placeholder coordinates
    AND ST_DWITHIN(
          ST_GEOGPOINT(lon, lat),                     -- station location
          ST_GEOGPOINT(-73.764, 41.197),              -- Chappaqua, NY
          32186.9                                      -- 20 miles in metres
        )
),
temp_obs AS (
  SELECT
    g.stn,
    g.wban,
    COUNT(*) AS valid_temp_days
  FROM `bigquery-public-data.noaa_gsod.gsod20*` AS g
  JOIN target_stations AS s
    ON g.stn = s.usaf AND g.wban = s.wban
  WHERE _TABLE_SUFFIX IN ('11','12','13','14','15','16','17','18','19','20')  -- 2011‑2020
    AND g.temp <> 9999.9                                                      -- exclude missing temp
  GROUP BY g.stn, g.wban
)

SELECT
  s.usaf  AS station_usaf,
  s.wban  AS station_wban,
  s.station_name,
  s.lat   AS latitude,
  s.lon   AS longitude,
  COALESCE(t.valid_temp_days, 0) AS valid_temperature_observations_2011_2020
FROM target_stations AS s
LEFT JOIN temp_obs AS t
  ON s.usaf = t.stn AND s.wban = t.wban
ORDER BY valid_temperature_observations_2011_2020 DESC, station_usaf, station_wban;