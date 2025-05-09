WITH candidate_ports AS (
  SELECT
    p.port_name,
    ANY_VALUE(p.port_geom) AS port_geom            -- one representative geometry per port
  FROM `bigquery-public-data.geo_international_ports.world_port_index` AS p
  JOIN `bigquery-public-data.geo_us_boundaries.states`                AS s
  ON  ST_WITHIN(p.port_geom, s.state_geom)                            -- port inside a U.S. state
  WHERE p.region_number = '6585'                                      -- requested region
  GROUP BY p.port_name
),
storm_snapshots AS (
  SELECT
    ST_BUFFER(
      ST_GeogPoint(longitude, latitude),
      usa_roci * 1852                                                 -- nm → metres
    ) AS storm_area
  FROM `bigquery-public-data.noaa_hurricanes.hurricanes`
  WHERE basin = 'NA'                                                  -- North Atlantic
    AND COALESCE(usa_wind, wmo_wind) >= 35                            -- ≥ 35‑kt winds
    AND usa_roci IS NOT NULL AND usa_roci > 0
    AND LOWER(name) <> 'not_named'                                    -- exclude unnamed storms
)
SELECT
  p.port_name,
  COUNT(*) AS frequency
FROM candidate_ports AS p
JOIN storm_snapshots AS s
ON  ST_WITHIN(p.port_geom, s.storm_area)                              -- port inside storm area
GROUP BY p.port_name
ORDER BY frequency DESC, p.port_name
LIMIT 1;