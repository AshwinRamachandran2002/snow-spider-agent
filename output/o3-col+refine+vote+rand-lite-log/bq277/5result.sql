WITH us_ports AS (
  SELECT
    p.port_name,
    p.port_geom
  FROM
    `bigquery-public-data.geo_international_ports.world_port_index` AS p
  JOIN
    `bigquery-public-data.geo_us_boundaries.states`                 AS s
  ON
    ST_CONTAINS(s.state_geom, p.port_geom)            -- keep only U.S. ports
  WHERE
    p.region_number = '6585'                          -- requested region
),
storm_points AS (
  SELECT
    ST_GEOGPOINT(longitude, latitude)                                  AS storm_pt,
    GREATEST(usa_r34_ne, usa_r34_se, usa_r34_sw, usa_r34_nw) * 1852    AS radius_m
  FROM
    `bigquery-public-data.noaa_hurricanes.hurricanes`
  WHERE
    basin = 'NA'                              -- North Atlantic
    AND name <> 'NOT_NAMED'                   -- exclude unnamed storms
    AND COALESCE(usa_wind, wmo_wind) >= 35    -- ≥ 35-kt winds
    AND GREATEST(usa_r34_ne, usa_r34_se, usa_r34_sw, usa_r34_nw) IS NOT NULL
)
SELECT
  p.port_name
FROM
  us_ports AS p
JOIN
  storm_points AS sp
ON
  ST_DWithin(p.port_geom, sp.storm_pt, sp.radius_m)   -- port inside wind radius
GROUP BY
  p.port_name
ORDER BY
  COUNT(*) DESC                       -- most frequent “hits”
LIMIT 1;