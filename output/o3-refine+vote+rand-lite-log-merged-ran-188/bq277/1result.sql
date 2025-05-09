-- Port (region 6585, inside a U.S. state) with the greatest number of
-- North-Atlantic named tropical-storm (≥35 kt) “hits”
SELECT
  p.index_number,
  p.port_name,
  COUNT(*) AS hit_count
FROM (
  -- region-6585 ports that fall within a U.S. state polygon
  SELECT p.*
  FROM `bigquery-public-data.geo_international_ports.world_port_index` AS p
  JOIN `bigquery-public-data.geo_us_boundaries.states`               AS s
  ON  ST_CONTAINS(s.state_geom, p.port_geom)
  WHERE p.region_number = '6585'
) AS p
JOIN (
  -- North-Atlantic storm points: named, ≥35 kt
  SELECT
    sid,
    iso_time,
    name,
    ST_GEOGPOINT(longitude, latitude) AS storm_pt,
    GREATEST(
      COALESCE(usa_r34_ne,0), COALESCE(usa_r34_se,0),
      COALESCE(usa_r34_sw,0), COALESCE(usa_r34_nw,0)
    ) AS max34kt_radius_nm          -- 34-kt wind radius (nautical miles)
  FROM `bigquery-public-data.noaa_hurricanes.hurricanes`
  WHERE basin = 'NA'
    AND usa_wind >= 35
    AND name <> 'NOT_NAMED'
) AS h
ON  h.max34kt_radius_nm > 0                              -- radius known
AND ST_DWITHIN(                                          -- port inside wind field
      p.port_geom,
      h.storm_pt,
      h.max34kt_radius_nm * 1852                        -- convert NM → metres
    )
GROUP BY p.index_number, p.port_name
ORDER BY hit_count DESC
LIMIT 1;