/* Ports in region 6585 that lie within U.S. states and were impacted
   (≤ 60 n mi ≈ 111 120 m) by named North-Atlantic storms with
   wind ≥ 35 kt and SSHS ≥ 0 (tropical-storm strength).               */

WITH ports AS (  -- candidate ports
    SELECT  p."index_number",
            p."port_name",
            p."port_geom",                       -- WKB
            ST_GEOGFROMWKB(p."port_geom") AS port_geog
    FROM    NOAA_PORTS.GEO_INTERNATIONAL_PORTS."WORLD_PORT_INDEX" p
    WHERE   p."region_number" = '6585'
),
states AS (      -- U.S. state polygons
    SELECT  s."state_name",
            ST_GEOGFROMWKB(s."state_geom") AS state_geog
    FROM    NOAA_PORTS.GEO_US_BOUNDARIES."STATES" s
),
ports_in_states AS (   -- keep only ports within a state
    SELECT  pt."index_number",
            pt."port_name",
            st."state_name",
            pt."port_geom",
            pt.port_geog
    FROM    ports  pt
    JOIN    states st
      ON    ST_WITHIN(pt.port_geog, st.state_geog)
),
storms AS (  -- named NA storms that satisfy intensity criteria
    SELECT  h."sid",
            h."name",
            h."iso_time",
            h."usa_wind",
            h."usa_sshs",
            ST_POINT(h."longitude", h."latitude") AS storm_geog
    FROM    NOAA_PORTS.NOAA_HURRICANES."HURRICANES" h
    WHERE   h."basin"      = 'NA'
      AND   h."name"      <> 'NOT_NAMED'
      AND   h."usa_wind"  >= 35
      AND   h."usa_sshs"  >= 0
      AND   h."latitude"  IS NOT NULL
      AND   h."longitude" IS NOT NULL
)
SELECT
    ps."port_name",
    ps."state_name",

    -- ordered distinct years
    ARRAY_AGG(DISTINCT TO_VARCHAR(TO_TIMESTAMP_NTZ(h."iso_time"/1000000),'YYYY'))
      WITHIN GROUP (ORDER BY TO_VARCHAR(TO_TIMESTAMP_NTZ(h."iso_time"/1000000),'YYYY'))
        AS storm_years,

    COUNT(DISTINCT h."sid")                                AS storm_count,

    -- alphabetical distinct storm names
    ARRAY_AGG(DISTINCT h."name") WITHIN GROUP (ORDER BY h."name") AS storm_names,

    AVG(h."usa_sshs")                                      AS avg_storm_category,
    AVG(h."usa_wind")                                      AS avg_wind_kt,

    ps."port_geom"                                         AS port_wkb,

    ARRAY_AGG(DISTINCT ST_ASWKB(h.storm_geog))             AS storm_geoms_wkb
FROM      ports_in_states ps
JOIN      storms          h
  ON      ST_DISTANCE(ps.port_geog, h.storm_geog) <= 111120  -- ≤ 60 n mi
GROUP BY  ps."port_name",
          ps."state_name",
          ps."port_geom"
ORDER BY  ps."state_name",
          ps."port_name";