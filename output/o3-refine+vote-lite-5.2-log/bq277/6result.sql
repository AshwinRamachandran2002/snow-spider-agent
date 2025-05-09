-- Port in region 6585 that most often lies inside the 34‑kt wind
-- envelope of named North‑Atlantic tropical storms (≥ 35 kt),
-- excluding storms named “NOT_NAMED”
WITH region_ports AS (
  SELECT
    index_number,
    port_name,
    port_geom
  FROM `bigquery-public-data.geo_international_ports.world_port_index`
  WHERE region_number = '6585'                     -- requested region
),
us_region_ports AS (                           -- keep only ports on U.S. soil
  SELECT p.*
  FROM region_ports AS p
  JOIN `bigquery-public-data.geo_us_boundaries.states` AS st
  ON ST_WITHIN(p.port_geom, st.state_geom)
),
named_na_storm_points AS (                     -- 34‑kt+ points of named storms
  SELECT
    sid,
    ST_GeogPoint(longitude, latitude)          AS center_pt,
    GREATEST(
      IFNULL(usa_r34_ne,0),
      IFNULL(usa_r34_se,0),
      IFNULL(usa_r34_sw,0),
      IFNULL(usa_r34_nw,0)
    )                                          AS r34_nm                -- n mi
  FROM `bigquery-public-data.noaa_hurricanes.hurricanes`
  WHERE basin        = 'NA'                    -- North Atlantic
    AND name        <> 'NOT_NAMED'             -- exclude unnamed
    AND usa_wind    >= 35                      -- ≥ 35‑kt wind (tropical‑storm)
),
storm_envelopes AS (                           -- build 34‑kt wind buffers
  SELECT
    sid,
    ST_BUFFER(center_pt, r34_nm * 1852) AS env_geom       -- metres
  FROM named_na_storm_points
  WHERE r34_nm > 0                                         -- need a radius
),
port_storm_hits AS (                           -- ports inside any envelope
  SELECT DISTINCT
    p.port_name,
    s.sid
  FROM us_region_ports AS p
  JOIN storm_envelopes  AS s
  ON ST_WITHIN(p.port_geom, s.env_geom)
)
SELECT
  port_name
FROM port_storm_hits
GROUP BY port_name
ORDER BY COUNT(DISTINCT sid) DESC            -- most frequent appearances
LIMIT 1;