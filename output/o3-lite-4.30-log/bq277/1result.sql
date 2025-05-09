WITH candidate_ports AS (
  SELECT
    p.index_number,
    p.port_name,
    p.port_geom
  FROM
    `bigquery-public-data.geo_international_ports.world_port_index` AS p
  JOIN
    `bigquery-public-data.geo_us_boundaries.states` AS s
  ON
    ST_CONTAINS(s.state_geom, p.port_geom)
  WHERE
    p.region_number = '6585'
),
storm_fixes AS (
  SELECT
    ST_GeogPoint(longitude, latitude) AS center_pt,
    GREATEST(usa_r34_ne, usa_r34_se, usa_r34_sw, usa_r34_nw) AS radius_nm
  FROM
    `bigquery-public-data.noaa_hurricanes.hurricanes`
  WHERE
    basin = 'NA'
    AND name <> 'NOT_NAMED'
    AND usa_wind >= 35
    AND GREATEST(usa_r34_ne, usa_r34_se, usa_r34_sw, usa_r34_nw) IS NOT NULL
)
SELECT
  p.port_name,
  COUNT(*) AS frequency
FROM
  candidate_ports AS p
JOIN
  storm_fixes AS h
ON
  ST_DWithin(p.port_geom, h.center_pt, h.radius_nm * 1852)  -- convert nautical miles to metres
GROUP BY
  p.port_name
ORDER BY
  frequency DESC,
  p.port_name
LIMIT 1;