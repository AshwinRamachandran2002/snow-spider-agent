-- Which port in region 6585 (within a U.S. state) most often lies inside the
-- 34‑kt wind radius of named North‑Atlantic tropical cyclones (≥35 kt)?

WITH region_ports AS (   -- ports in the requested region
  SELECT
    index_number,
    port_name,
    port_geom
  FROM `bigquery-public-data.geo_international_ports.world_port_index`
  WHERE region_number = '6585'
),

us_region_ports AS (     -- keep only those that sit inside a U.S‑state polygon
  SELECT p.*
  FROM region_ports AS p
  JOIN `bigquery-public-data.geo_us_boundaries.states` AS s
  ON ST_WITHIN(p.port_geom, s.state_geom)
),

atl_storm_points AS (    -- storm fixes that meet all cyclone criteria
  SELECT
    sid,
    iso_time,
    name,
    longitude,
    latitude,
    GREATEST(usa_r34_ne, usa_r34_se, usa_r34_sw, usa_r34_nw) AS r34_nm,
    ST_GEOGPOINT(longitude, latitude)                       AS eye_geom
  FROM `bigquery-public-data.noaa_hurricanes.hurricanes`
  WHERE basin = 'NA'                          -- North‑Atlantic basin
    AND name NOT IN ('NOT_NAMED', '')         -- exclude unnamed systems
    AND (usa_wind >= 35                      -- at least 35‑kt wind
         OR (usa_wind IS NULL AND wmo_wind >= 35))
),

atl_storm_points_w_radius AS (  -- retain fixes that actually have a 34‑kt radius
  SELECT
    sid,
    iso_time,
    name,
    eye_geom,
    r34_nm * 1852.0 AS radius_m              -- convert nmi → metres
  FROM atl_storm_points
  WHERE r34_nm IS NOT NULL
),

port_hits AS (            -- count how many times each port sits inside a storm disk
  SELECT
    p.index_number,
    COUNT(*) AS hit_ct
  FROM us_region_ports AS p
  JOIN atl_storm_points_w_radius AS s
  ON ST_DWITHIN(p.port_geom, s.eye_geom, s.radius_m)
  GROUP BY p.index_number
),

top_port AS (             -- pick the single most‑frequent port
  SELECT
    index_number,
    hit_ct,
    RANK() OVER (ORDER BY hit_ct DESC, index_number) AS rnk
  FROM port_hits
)

SELECT
  p.index_number,
  p.port_name,
  t.hit_ct AS storm_hit_count
FROM top_port AS t
JOIN us_region_ports AS p
  USING (index_number)
WHERE t.rnk = 1;