-- Port inside‑storm frequency in the North‑Atlantic
WITH ports AS (
  -- 1.  Ports in region 6585
  SELECT
    index_number,
    port_name,
    port_geom
  FROM `bigquery-public-data.geo_international_ports.world_port_index`
  WHERE region_number = '6585'
),
us_ports AS (
  -- 2.  Keep only those that fall inside a U.S. state boundary
  SELECT p.*
  FROM ports      AS p
  JOIN `bigquery-public-data.geo_us_boundaries.states` AS s
  ON  ST_WITHIN(p.port_geom, s.state_geom)
),
storm_pts AS (
  -- 3.  North‑Atlantic named storm fixes with wind ≥35 kt
  SELECT
    sid,
    iso_time,
    name,
    ST_GEOGPOINT(longitude, latitude)          AS pt,
    COALESCE(usa_wind, wmo_wind)               AS wind_kt,
    GREATEST(
      IFNULL(usa_r34_ne,0), IFNULL(usa_r34_se,0),
      IFNULL(usa_r34_sw,0), IFNULL(usa_r34_nw,0)
    )                                          AS r34_nm   -- 34‑kt radii
  FROM `bigquery-public-data.noaa_hurricanes.hurricanes`
  WHERE basin = 'NA'
    AND name <> 'NOT_NAMED'
),
valid_storm_pts AS (
  SELECT *
  FROM storm_pts
  WHERE wind_kt >= 35           -- at least tropical‑storm force
    AND r34_nm  > 0             -- have a usable wind radius
),
hits AS (
  -- 4.  Count how many storm‑fix areas each port falls inside
  SELECT
    p.index_number,
    p.port_name,
    COUNT(*) AS occurrences
  FROM us_ports            AS p
  JOIN valid_storm_pts     AS s
  ON ST_DWITHIN(p.port_geom, s.pt, s.r34_nm * 1852)   -- convert nmi → metres
  GROUP BY p.index_number, p.port_name
)
-- 5.  Return the single most‑frequent port
SELECT port_name
FROM hits
ORDER BY occurrences DESC, port_name
LIMIT 1;