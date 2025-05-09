-- Port in region 6585 that is intersected by the greatest number of
-- named North-Atlantic storms (≥ 35 kt) whose footprints are built
-- from all 6-hour positions.
WITH us_region_6585_ports AS (
  SELECT
    p.index_number,
    p.port_name,
    s.state_name,
    p.port_geom
  FROM
    `bigquery-public-data.geo_international_ports.world_port_index` AS p
  JOIN
    `bigquery-public-data.geo_us_boundaries.states`                 AS s
  ON
    ST_CONTAINS(s.state_geom, p.port_geom)          -- keep only ports inside U.S. states
  WHERE
    p.region_number = '6585'                        -- requested region
),
atlantic_storm_areas AS (
  SELECT
    sid,
    -- a simple footprint for each storm built from all reported positions
    ST_CONVEXHULL(
      ST_UNION_AGG(ST_GEOGPOINT(longitude, latitude))
    ) AS storm_geom
  FROM
    `bigquery-public-data.noaa_hurricanes.hurricanes`
  WHERE
    basin = 'NA'                                    -- North Atlantic
    AND name <> 'NOT_NAMED'                         -- exclude unnamed systems
    AND COALESCE(usa_wind, wmo_wind) >= 35          -- ≥ 35 kt
  GROUP BY sid
),
port_storm_counts AS (
  SELECT
    p.index_number,
    p.port_name,
    p.state_name,
    COUNT(*) AS storms_hit
  FROM
    us_region_6585_ports AS p
  JOIN
    atlantic_storm_areas AS s
  ON
    ST_CONTAINS(s.storm_geom, p.port_geom)          -- port inside storm footprint
  GROUP BY
    p.index_number, p.port_name, p.state_name
)
SELECT
  index_number,
  port_name,
  state_name,
  storms_hit
FROM
  port_storm_counts
ORDER BY
  storms_hit DESC
LIMIT 1;