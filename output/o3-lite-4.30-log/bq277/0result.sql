SELECT
  p.port_name,
  COUNT(DISTINCT h.sid) AS frequency
FROM
  `bigquery-public-data.geo_international_ports.world_port_index` AS p
JOIN
  `bigquery-public-data.geo_us_boundaries.states` AS s
ON
  ST_Intersects(p.port_geom, s.state_geom)
JOIN
  `bigquery-public-data.noaa_hurricanes.hurricanes` AS h
ON
  ST_DWithin(
    p.port_geom,
    ST_GeogPoint(h.longitude, h.latitude),
    50000  -- 50 km
  )
WHERE
  p.region_number = '6585'
  AND h.basin = 'NA'
  AND h.name <> 'NOT_NAMED'
  AND COALESCE(h.usa_wind, h.wmo_wind, 0) >= 35
GROUP BY
  p.port_name
ORDER BY
  frequency DESC,
  p.port_name
LIMIT 1;