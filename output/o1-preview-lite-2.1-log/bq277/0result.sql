SELECT
  p.port_name
FROM
  `bigquery-public-data.geo_international_ports.world_port_index` AS p
JOIN
  `bigquery-public-data.noaa_hurricanes.hurricanes` AS h
ON
  ST_DWITHIN(p.port_geom, ST_GEOGPOINT(h.longitude, h.latitude), 100000) -- Within 100 km
JOIN
  `bigquery-public-data.geo_us_boundaries.states` AS s
ON
  ST_WITHIN(p.port_geom, s.state_geom)
WHERE
  p.region_number = '6585'
  AND h.basin = 'NA'
  AND h.wmo_wind >= 35
  AND h.name IS NOT NULL
  AND h.name != 'NOT_NAMED'
GROUP BY
  p.port_name
ORDER BY
  COUNT(DISTINCT h.sid) DESC
LIMIT 1;