-- Port in region 6585 that most often lies inside 34‑kt wind areas 
-- of named (≠ 'NOT_NAMED') tropical storms (≥35 kt) in the North Atlantic

WITH candidate_ports AS (
  SELECT
    p.index_number,
    p.port_name,
    p.port_geom
  FROM `bigquery-public-data.geo_international_ports.world_port_index` AS p
  JOIN `bigquery-public-data.geo_us_boundaries.states`               AS s
  ON  ST_WITHIN(p.port_geom, s.state_geom)            -- restrict to U.S. states
  WHERE p.region_number = '6585'
),

storm_points AS (         -- storm fixes that qualify
  SELECT
    sid,
    latitude,
    longitude,
    GREATEST(usa_r34_ne, usa_r34_se, usa_r34_sw, usa_r34_nw) AS r34_nm -- nm = nautical miles
  FROM `bigquery-public-data.noaa_hurricanes.hurricanes`
  WHERE basin      = 'NA'               -- North Atlantic
    AND name      <> 'NOT_NAMED'        -- ignore unnamed systems
    AND usa_wind  >= 35                 -- ≥ 35‑kt winds
),

storm_areas AS (          -- buffer each fix by its 34‑kt radius
  SELECT
    sid,
    ST_BUFFER(
      ST_GEOGPOINT(longitude, latitude),
      r34_nm * 1852                          -- convert nm → metres
    ) AS storm_geom
  FROM storm_points
  WHERE r34_nm IS NOT NULL AND r34_nm > 0
),

port_hits AS (            -- count distinct storms affecting each port
  SELECT
    p.index_number,
    p.port_name,
    COUNT(DISTINCT s.sid) AS storm_count
  FROM candidate_ports AS p
  JOIN storm_areas     AS s
  ON ST_WITHIN(p.port_geom, s.storm_geom)
  GROUP BY p.index_number, p.port_name
)

SELECT
  port_name
FROM port_hits
ORDER BY storm_count DESC
LIMIT 1;