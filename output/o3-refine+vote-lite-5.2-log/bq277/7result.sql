-- Port inside U.S. state that most often falls within the 34‑kt wind envelopes
-- of named (≠ 'NOT_NAMED') North‑Atlantic tropical systems (≥35 kt)

WITH ports_region AS (
  SELECT
    index_number,
    port_name,
    port_geom
  FROM
    `bigquery-public-data.geo_international_ports.world_port_index`
  WHERE
    region_number = '6585'
),
us_state_ports AS (         -- keep only ports that lie inside a U.S. state
  SELECT p.*
  FROM ports_region p
  JOIN `bigquery-public-data.geo_us_boundaries.states` s
  ON ST_INTERSECTS(p.port_geom, s.state_geom)
),
na_tropical_pts AS (        -- storm fixes meeting all meteorological criteria
  SELECT
    sid,
    name,
    /* centre point of the fix */
    ST_GEOGPOINT(longitude, latitude)                 AS centre,
    /* maximum reported 34‑kt radius (nm) converted to metres */
    GREATEST(
      COALESCE(usa_r34_ne,0),
      COALESCE(usa_r34_se,0),
      COALESCE(usa_r34_sw,0),
      COALESCE(usa_r34_nw,0)
    ) * 1852                                            AS r34_m
  FROM `bigquery-public-data.noaa_hurricanes.hurricanes`
  WHERE
    basin = 'NA'                                   -- North Atlantic basin
    AND name <> 'NOT_NAMED'                       -- exclude unnamed
    AND COALESCE(usa_wind, wmo_wind, 0) >= 35     -- ≥35‑kt wind speed
),
na_tropical_areas AS (      -- buffer by reported 34‑kt wind radius
  SELECT
    sid,
    name,
    ST_BUFFER(centre, r34_m) AS storm_area
  FROM na_tropical_pts
  WHERE r34_m > 0                               -- need a finite wind radius
)
SELECT
  p.port_name,
  COUNT(*) AS hits
FROM us_state_ports         AS p
JOIN na_tropical_areas      AS a
ON  ST_CONTAINS(a.storm_area, p.port_geom)
GROUP BY p.port_name
ORDER BY hits DESC
LIMIT 1;