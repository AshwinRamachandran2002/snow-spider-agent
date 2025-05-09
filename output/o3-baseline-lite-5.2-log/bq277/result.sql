-- Port that meets all the stated conditions
WITH candidate_ports AS (
  -- 1) ports in region 6585 whose point falls inside a U.S. state boundary
  SELECT
    p.index_number,
    p.port_name,
    p.port_geom
  FROM
    `bigquery-public-data.geo_international_ports.world_port_index` AS p
  JOIN
    `bigquery-public-data.geo_us_boundaries.states`              AS st
  ON
    ST_Intersects(p.port_geom, st.state_geom)
  WHERE
    p.region_number = '6585'               -- requested region
    AND p.country       = 'US'             -- make sure it is a U.S. port
),

storm_buffers AS (
  -- 2) 34‑kt wind envelopes (radius R34) of named NA‑basin storms (wind ≥35 kt)
  SELECT
    sid,                                      -- storm id
    iso_time,                                 -- time stamp (not used later, kept for uniqueness)
    ST_Buffer(                                -- circular area of 34‑kt winds
      ST_GeogPoint(longitude, latitude),
      GREATEST(usa_r34_ne, usa_r34_se,        -- biggest reported 34‑kt radius
               usa_r34_sw, usa_r34_nw) * 1852 -- ⇒ metres (1 n.mi = 1852 m)
    ) AS r34_geom
  FROM (
    SELECT *,
           COALESCE(usa_wind, wmo_wind, 0) AS max_wind_kt
    FROM `bigquery-public-data.noaa_hurricanes.hurricanes`
    WHERE basin = 'NA'                    -- North Atlantic
      AND name  <> 'NOT_NAMED'            -- exclude unnamed storms
  )
  WHERE
    max_wind_kt >= 35                     -- tropical‑storm strength
    AND GREATEST(usa_r34_ne, usa_r34_se,
                 usa_r34_sw, usa_r34_nw) IS NOT NULL   -- need a radius
),

hits AS (
  -- 3) every (port, storm‑time) intersection
  SELECT
    p.index_number,
    p.port_name
  FROM
    candidate_ports  AS p
  JOIN
    storm_buffers    AS s
  ON
    ST_Intersects(p.port_geom, s.r34_geom)
)

-- 4) most‑frequent port
SELECT
  port_name,
  COUNT(*) AS times_inside_tropical_storm_area
FROM hits
GROUP BY port_name
ORDER BY times_inside_tropical_storm_area DESC, port_name
LIMIT 1;