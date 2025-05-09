SELECT p.port_name
FROM `bigquery-public-data.geo_international_ports.world_port_index` AS p
JOIN `bigquery-public-data.geo_us_boundaries.states` AS s
  ON ST_Contains(s.state_geom, p.port_geom)
JOIN `bigquery-public-data.noaa_hurricanes.hurricanes` AS h
  ON ST_DWithin(
    p.port_geom,
    ST_GEOGPOINT(h.usa_longitude, h.usa_latitude),
    50000  -- Distance in meters (50 kilometers)
  )
WHERE p.region_number = '6585'
  AND p.country = 'US'
  AND h.basin = 'NA'
  AND h.usa_wind >= 35
  AND h.name != 'NOT_NAMED'
GROUP BY p.port_name
ORDER BY COUNT(*) DESC
LIMIT 1;