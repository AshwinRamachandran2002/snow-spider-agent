WITH region_ports AS (
  -- Ports that belong to region 6585
  SELECT 
    index_number,
    port_name,
    port_geom
  FROM `bigquery-public-data.geo_international_ports.world_port_index`
  WHERE region_number = '6585'
),
us_ports AS (
  -- Keep only the ports that lie inside a U.S. state boundary
  SELECT 
    p.index_number,
    p.port_name,
    p.port_geom
  FROM region_ports AS p
  JOIN `bigquery-public-data.geo_us_boundaries.states` AS s
  ON ST_WITHIN(p.port_geom, s.state_geom)
),
atl_storm_points AS (
  -- North‑Atlantic storm points: named, ≥ 35 kt, exclude “NOT_NAMED”
  SELECT
    ST_GEOGPOINT(longitude, latitude) AS storm_geom
  FROM `bigquery-public-data.noaa_hurricanes.hurricanes`
  WHERE basin = 'NA'
    AND usa_wind >= 35
    AND LOWER(name) <> 'not_named'
)
-- Port with the most storm‑proximity hits (≤ 100 km)
SELECT
  u.index_number,
  u.port_name,
  COUNT(*) AS storm_point_hits
FROM us_ports AS u
JOIN atl_storm_points AS t
ON ST_DWITHIN(u.port_geom, t.storm_geom, 100000)  -- 100 km radius
GROUP BY
  u.index_number,
  u.port_name
ORDER BY
  storm_point_hits DESC
LIMIT 1;