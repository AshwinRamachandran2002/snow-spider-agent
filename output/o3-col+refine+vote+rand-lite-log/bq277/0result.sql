WITH region_6585_us_ports AS (
  -- ports from region 6585 that fall inside a U.S. state polygon
  SELECT
    p.index_number,
    p.port_name,
    p.port_geom
  FROM `bigquery-public-data.geo_international_ports.world_port_index` AS p
  JOIN `bigquery-public-data.geo_us_boundaries.states`               AS s
    ON ST_CONTAINS(s.state_geom, p.port_geom)
  WHERE p.region_number = '6585'
),
na_storm_pts AS (
  -- North-Atlantic named storm points (≥ 35 kt) with a usable 34-kt wind radius
  SELECT
    sid,
    GREATEST(
      IFNULL(usa_r34_ne,0),
      IFNULL(usa_r34_se,0),
      IFNULL(usa_r34_sw,0),
      IFNULL(usa_r34_nw,0)
    )                    AS r34_nm,          -- radius in nautical miles
    ST_GeogPoint(longitude, latitude) AS storm_geom
  FROM `bigquery-public-data.noaa_hurricanes.hurricanes`
  WHERE basin = 'NA'
    AND name <> 'NOT_NAMED'
    AND COALESCE(usa_wind, wmo_wind) >= 35
),
port_storm_counts AS (
  -- how many distinct storms ever enclosed each port
  SELECT
    p.port_name,
    COUNT(DISTINCT s.sid) AS storm_hits
  FROM region_6585_us_ports AS p
  JOIN na_storm_pts        AS s
    ON s.r34_nm > 0
   AND ST_DWithin(
         p.port_geom,
         s.storm_geom,
         1852 * s.r34_nm          -- convert nautical-mile radius to metres
       )
  GROUP BY p.port_name
)
-- the single port with the most storm hits
SELECT port_name
FROM port_storm_counts
ORDER BY storm_hits DESC
LIMIT 1;