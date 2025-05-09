-- Corrected query: uses BigQuery’s ST_GEOGPOINT instead of ST_MAKEPOINT
WITH target AS (
  -- Chappaqua, NY
  SELECT ST_GEOGPOINT(-73.764, 41.197) AS geom
),

nearby_stations AS (
  SELECT
    s.usaf,
    s.wban,
    TRIM(s.name)                         AS station_name,
    s.lat,
    s.lon,
    ST_DISTANCE(
      ST_GEOGPOINT(s.lon, s.lat),
      (SELECT geom FROM target)
    ) AS dist_m
  FROM `bigquery-public-data.noaa_gsod.stations` AS s
  WHERE s.lat IS NOT NULL
    AND s.lon IS NOT NULL
    -- within 20 miles ≈ 32 186.9 m
    AND ST_DWITHIN(
          ST_GEOGPOINT(s.lon, s.lat),
          (SELECT geom FROM target),
          32186.9
        )
),

temp_counts AS (
  SELECT
    stn  AS usaf,
    wban,
    COUNT(*) AS valid_temp_obs
  FROM `bigquery-public-data.noaa_gsod.gsod*`
  WHERE _TABLE_SUFFIX BETWEEN '2011' AND '2020'
    AND temp IS NOT NULL
    AND temp != 9999.9     -- exclude invalid/missing temps
  GROUP BY usaf, wban
)

SELECT
  n.usaf,
  n.wban,
  n.station_name,
  ROUND(n.lat, 4)                              AS latitude,
  ROUND(n.lon, 4)                              AS longitude,
  ROUND(n.dist_m / 1609.34, 2)                 AS distance_miles,
  COALESCE(t.valid_temp_obs, 0)                AS valid_temperature_observations_2011_2020
FROM nearby_stations AS n
LEFT JOIN temp_counts AS t
USING (usaf, wban)
ORDER BY distance_miles;