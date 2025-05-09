WITH ports AS (
  SELECT
    port_name,
    ST_GEOGPOINT(port_longitude, port_latitude) AS port_geom
  FROM
    `bigquery-public-data.geo_international_ports.world_port_index`
  WHERE
    region_number = '6585'
),
ports_with_state AS (
  SELECT
    p.port_name,
    p.port_geom
  FROM
    ports p
  JOIN
    `bigquery-public-data.geo_us_boundaries.states` s
  ON
    ST_CONTAINS(s.state_geom, p.port_geom)
),
hurricanes AS (
  SELECT
    name,
    ST_GEOGPOINT(longitude, latitude) AS hurricane_geom
  FROM
    `bigquery-public-data.noaa_hurricanes.hurricanes`
  WHERE
    basin = 'NA'
    AND wmo_wind >= 35
    AND name IS NOT NULL
)
SELECT
  p.port_name
FROM
  ports_with_state p
JOIN
  hurricanes h
ON
  ST_DWithin(p.port_geom, h.hurricane_geom, 200000)
GROUP BY
  p.port_name
ORDER BY
  COUNT(*) DESC
LIMIT
  1;