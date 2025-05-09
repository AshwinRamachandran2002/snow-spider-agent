-- Which region-6585 U.S. port is intersected most often
-- by ≥35-kt named North-Atlantic storm points (within 100 km)?
WITH us_ports AS (
  SELECT
    p.index_number,
    p.port_name,
    p.port_geom
  FROM
    `bigquery-public-data.geo_international_ports.world_port_index` AS p
  JOIN
    `bigquery-public-data.geo_us_boundaries.states`                AS s
  ON
    ST_CONTAINS(s.state_geom, p.port_geom)          -- keep only ports inside a U.S. state
  WHERE
    p.region_number = '6585'                        -- requested region
),
storms AS (
  SELECT
    ST_GeogPoint(longitude, latitude) AS storm_pt
  FROM
    `bigquery-public-data.noaa_hurricanes.hurricanes`
  WHERE
    basin = 'NA'                                   -- North Atlantic
    AND name <> 'NOT_NAMED'                        -- ignore unnamed
    AND COALESCE(usa_wind, wmo_wind) >= 35         -- ≥35-kt winds
)
SELECT
  p.port_name AS most_frequent_port
FROM
  us_ports AS p
JOIN
  storms   AS s
ON
  ST_DWITHIN(p.port_geom, s.storm_pt, 100000)      -- within 100 km (≈54 nmi)
GROUP BY
  p.port_name
ORDER BY
  COUNT(*) DESC
LIMIT 1;