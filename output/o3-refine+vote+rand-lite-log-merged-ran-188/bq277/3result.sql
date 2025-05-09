-- Most frequently impacted U.S. port (region 6585) by ≥35-kt named
-- North-Atlantic tropical-storm points that come within 100 km
SELECT
  p.port_name
FROM `bigquery-public-data.geo_international_ports.world_port_index` AS p
JOIN `bigquery-public-data.geo_us_boundaries.states`                AS s
  ON ST_CONTAINS(s.state_geom, p.port_geom)               -- ensure port is inside a U.S. state
JOIN `bigquery-public-data.noaa_hurricanes.hurricanes`              AS h
  ON  h.basin         = 'NA'                                        -- North Atlantic basin
  AND LOWER(h.name)  <> 'not_named'                                 -- exclude “NOT_NAMED”
  AND h.usa_wind      >= 35                                         -- at least 35 kt
  AND ST_DWithin(                                       -- storm point within 100 km of port
        ST_GeogPoint(h.longitude, h.latitude),
        p.port_geom,
        100000                                                    ) -- metres
WHERE p.region_number = '6585'
GROUP BY p.port_name
ORDER BY COUNT(*) DESC
LIMIT 1;