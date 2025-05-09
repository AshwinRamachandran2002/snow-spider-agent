-- Port in region 6585 that most often lies inside the 34‑kt wind‐circle
-- of named North‑Atlantic tropical storms (≥35 kt and not ‘NOT_NAMED’)
WITH us_ports AS (
  SELECT
    p.index_number,
    p.port_name,
    p.port_geom
  FROM
    `bigquery-public-data.geo_international_ports.world_port_index` p
  JOIN
    `bigquery-public-data.geo_us_boundaries.states` s
  ON
    ST_INTERSECTS(p.port_geom, s.state_geom)            -- inside a U.S. state
  WHERE
    p.region_number = '6585'
    AND p.country = 'US'                                -- redundancy check
),

storm_pts AS (
  SELECT
    sid,
    iso_time,
    -- maximum 34‑kt wind radius in nautical miles
    GREATEST(usa_r34_ne, usa_r34_se, usa_r34_sw, usa_r34_nw) AS r34_nm,
    ST_GEOGPOINT(longitude, latitude)                  AS storm_center
  FROM
    `bigquery-public-data.noaa_hurricanes.hurricanes`
  WHERE
        basin = 'NA'                                   -- North Atlantic
    AND name <> 'NOT_NAMED'                            -- named storms only
    AND COALESCE(wmo_wind, usa_wind, 0) >= 35          -- ≥35‑kt winds
),

-- keep only points where a usable gale‑radius is present (>0)
storm_areas AS (
  SELECT
    sid,
    iso_time,
    ST_BUFFER(storm_center, r34_nm * 1852) AS gale_area   -- convert NM → metres
  FROM
    storm_pts
  WHERE
    r34_nm IS NOT NULL
    AND r34_nm > 0
),

hits AS (
  SELECT
    p.port_name,
    COUNT(*) AS hit_cnt
  FROM
    us_ports  AS p
  JOIN
    storm_areas AS a
  ON
    ST_WITHIN(p.port_geom, a.gale_area)                  -- port inside storm area
  GROUP BY
    p.port_name
)

SELECT
  port_name
FROM
  hits
ORDER BY
  hit_cnt DESC
LIMIT
  1;