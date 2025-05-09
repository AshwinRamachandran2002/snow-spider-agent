-- Top‑hit port (region 6585) that sits within the 34‑kt wind envelope
-- of named North‑Atlantic tropical storms (≥35 kt), omitting “NOT_NAMED”.
WITH us_ports AS (   -- region‑6585 ports located inside any U.S. state
  SELECT
    p.index_number,
    p.port_name,
    p.port_geom
  FROM `bigquery-public-data.geo_international_ports.world_port_index` AS p
  JOIN `bigquery-public-data.geo_us_boundaries.states`              AS s
    ON ST_CONTAINS(s.state_geom, p.port_geom)
  WHERE p.region_number = '6585'
    AND p.country       = 'US'
),

storm_points AS (    -- each 6‑hour track point with a usable 34‑kt radius
  SELECT *
  FROM (
    SELECT
      sid,
      name,
      ST_GEOGPOINT(longitude, latitude) AS eye,
      GREATEST(
        IFNULL(usa_r34_ne, 0),
        IFNULL(usa_r34_se, 0),
        IFNULL(usa_r34_sw, 0),
        IFNULL(usa_r34_nw, 0)
      ) * 1852 AS radius_m                            -- n mi → metres
    FROM `bigquery-public-data.noaa_hurricanes.hurricanes`
    WHERE basin     = 'NA'           -- North Atlantic basin
      AND name     <> 'NOT_NAMED'    -- exclude unnamed storms
      AND usa_wind >= 35             -- ≥35 kt (tropical‑storm strength)
      AND longitude IS NOT NULL
      AND latitude  IS NOT NULL
  )
  WHERE radius_m > 0                 -- need a non‑zero wind envelope
)

SELECT
  p.port_name,
  COUNT(*) AS hits
FROM us_ports       AS p
JOIN storm_points   AS h
  ON ST_DWITHIN(p.port_geom, h.eye, h.radius_m)   -- port inside storm area
GROUP BY p.port_name
ORDER BY hits DESC
LIMIT 1;