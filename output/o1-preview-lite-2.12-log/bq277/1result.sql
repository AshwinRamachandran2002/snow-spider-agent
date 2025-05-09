SELECT 
  p.port_name
FROM 
  `bigquery-public-data.geo_international_ports.world_port_index` AS p
JOIN 
  `bigquery-public-data.geo_us_boundaries.states` AS s
ON 
  ST_Contains(s.state_geom, ST_GEOGPOINT(p.port_longitude, p.port_latitude))
JOIN
  `bigquery-public-data.noaa_hurricanes.hurricanes` AS h
ON 
  ST_DWithin(
    ST_GEOGPOINT(p.port_longitude, p.port_latitude),
    ST_GEOGPOINT(h.longitude, h.latitude),
    100000  -- 100 km in meters
  )
WHERE 
  p.region_number = '6585' 
  AND p.country = 'US' 
  AND h.basin = 'NA' 
  AND h.wmo_wind >= 35 
  AND LOWER(h.name) != 'not_named'
GROUP BY 
  p.port_name
ORDER BY 
  COUNT(*) DESC
LIMIT 1;