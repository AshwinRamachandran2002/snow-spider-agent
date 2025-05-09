-- Weather stations within 20 miles (~32 186.8 m) of Chappaqua, NY
-- together with the count of daily temperature records whose
-- temperature value is not the “missing” flag 9999.9
-- for the years 2011‑2020 (inclusive).

WITH
-- 1. Reference point for Chappaqua
chappaqua AS (
  SELECT ST_GEOGPOINT(-73.764, 41.197) AS geog
),

-- 2. Stations inside the 20‑mile radius
nearby AS (
  SELECT
    s.usaf,
    s.wban,
    TRIM(s.name)                 AS station_name,
    s.lat,
    s.lon,
    ST_DISTANCE(
      ST_GEOGPOINT(s.lon, s.lat),
      (SELECT geog FROM chappaqua)
    )                            AS distance_meters
  FROM `bigquery-public-data.noaa_gsod.stations` AS s
  WHERE s.lat IS NOT NULL
    AND s.lon IS NOT NULL
    -- 20 miles ≈ 32 186.8 m
    AND ST_DWITHIN(
          ST_GEOGPOINT(s.lon, s.lat),
          (SELECT geog FROM chappaqua),
          32186.8
        )
),

-- 3. Count valid (non‑missing) temperature observations 2011‑2020
obs AS (
  SELECT
    stn   AS usaf,
    wban,
    COUNTIF(temp <> 9999.9) AS valid_obs
  FROM `bigquery-public-data.noaa_gsod.gsod20*`
  WHERE _TABLE_SUFFIX BETWEEN '2011' AND '2020'
  GROUP BY usaf, wban
)

-- 4. Combine and present results
SELECT
  n.usaf,
  n.wban,
  n.station_name,
  n.lat,
  n.lon,
  ROUND(n.distance_meters / 1609.34, 2) AS distance_miles,
  IFNULL(o.valid_obs, 0)                AS valid_temp_observations
FROM nearby AS n
LEFT JOIN obs AS o
  ON n.usaf = o.usaf
 AND n.wban = o.wban
ORDER BY valid_temp_observations DESC,
         n.station_name;