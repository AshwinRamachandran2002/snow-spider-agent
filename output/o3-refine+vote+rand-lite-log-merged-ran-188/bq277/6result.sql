-- Top 6585-region U.S. port by count of distinct named NA storms (≥35 kt)
WITH us_ports AS (
  SELECT
    p.index_number,
    p.port_name,
    p.port_geom
  FROM `bigquery-public-data.geo_international_ports.world_port_index` AS p
  JOIN `bigquery-public-data.geo_us_boundaries.states`                AS s
    ON ST_WITHIN(p.port_geom, s.state_geom)   -- only ports inside a U.S. state
  WHERE p.region_number = '6585'              -- requested region
),
atl_storm_pts AS (
  SELECT
    sid,
    name,
    ST_GeogPoint(longitude, latitude) AS storm_pt
  FROM `bigquery-public-data.noaa_hurricanes.hurricanes`
  WHERE basin = 'NA'                          -- North Atlantic basin
    AND COALESCE(usa_wind, wmo_wind) >= 35    -- ≥ 35-kt winds
    AND LOWER(name) <> 'not_named'            -- exclude unnamed systems
),
tally AS (
  SELECT
    p.index_number,
    p.port_name,
    COUNT(DISTINCT h.sid) AS distinct_named_storms
  FROM us_ports AS p
  JOIN atl_storm_pts AS h
    ON ST_DWITHIN(p.port_geom, h.storm_pt, 92600)  -- within 50 nmi (≈92.6 km)
  GROUP BY p.index_number, p.port_name
)
SELECT
  index_number,
  port_name,
  distinct_named_storms
FROM tally
ORDER BY distinct_named_storms DESC
LIMIT 1;