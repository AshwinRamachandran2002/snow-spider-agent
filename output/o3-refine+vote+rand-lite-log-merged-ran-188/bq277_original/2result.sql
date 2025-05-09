-- 1)  Candidate ports: Region 6585
-- 2)  Keep only ports that lie inside a U.S. state polygon
-- 3)  North‑Atlantic storm fixes whose centre wind ≥35 kt, named, with a reported
--     radius of last closed isobar (usa_roci, n mi)
-- 4)  Count how often each port falls within that radius (converted to metres)
-- 5)  Return the port hit the largest number of times
WITH candidate_ports AS (
  SELECT
    index_number,
    port_name,
    port_geom
  FROM `bigquery-public-data.geo_international_ports.world_port_index`
  WHERE region_number = '6585'
),
us_ports AS (
  SELECT p.*
  FROM candidate_ports AS p
  JOIN `bigquery-public-data.geo_us_boundaries.states` AS s
    ON ST_CONTAINS(s.state_geom, p.port_geom)
),
storm_fixes AS (
  SELECT
    sid,
    iso_time,
    name,
    usa_roci,                    -- radius of closed isobar (nautical miles)
    ST_GEOGPOINT(longitude, latitude) AS fix_point
  FROM `bigquery-public-data.noaa_hurricanes.hurricanes`
  WHERE basin              = 'NA'          -- North Atlantic
    AND name              != 'NOT_NAMED'   -- exclude anonymous storms
    AND usa_wind           >= 35           -- ≥35 kt  (tropical‑storm force)
    AND longitude IS NOT NULL
    AND latitude  IS NOT NULL
    AND usa_roci   IS NOT NULL             -- need a radius to make an area
)
SELECT
  p.port_name,
  COUNT(*) AS times_inside_storm_area
FROM us_ports AS p
JOIN storm_fixes AS s
  ON ST_DWITHIN(
       p.port_geom,
       s.fix_point,
       s.usa_roci * 1852   -- convert nautical miles → metres
     )
GROUP BY p.port_name
ORDER BY times_inside_storm_area DESC
LIMIT 1;