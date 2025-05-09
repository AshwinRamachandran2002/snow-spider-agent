SELECT
  p.port_name,
  COUNT(DISTINCT h.name) AS storm_count
FROM
  `bigquery-public-data.geo_international_ports.world_port_index` p
JOIN
  `bigquery-public-data.noaa_hurricanes.hurricanes` h
ON
  ST_DWithin(
    p.port_geom,
    ST_GEOGPOINT(h.longitude, h.latitude),
    100000  -- 100 kilometers
  )
WHERE
  p.region_number = '6585'
  AND p.port_geom IS NOT NULL
  AND h.basin = 'NA'
  AND h.wmo_wind >= 35
  AND h.name IS NOT NULL
GROUP BY
  p.port_name
ORDER BY
  storm_count DESC
LIMIT 1;