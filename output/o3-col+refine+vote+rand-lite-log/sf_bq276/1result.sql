/*  Region-6585 U.S. ports that were within 50 km of a named
    North-Atlantic storm fix (≥ 35 kt, ≥ TS) – summary per port            */

WITH ports AS (   -- Region-6585 U.S. ports
    SELECT  p."index_number",
            p."port_name",
            TO_GEOGRAPHY(p."port_geom")                 AS port_geog,
            ST_ASTEXT(TO_GEOGRAPHY(p."port_geom"))      AS port_wkt
    FROM NOAA_PORTS.GEO_INTERNATIONAL_PORTS."WORLD_PORT_INDEX" p
    WHERE p."region_number" = '6585'
      AND p."country"       = 'US'
),

port_state AS (   -- ports that fall inside a U.S. state polygon
    SELECT  p.*,
            s."state_name"
    FROM ports p
    JOIN NOAA_PORTS.GEO_US_BOUNDARIES."STATES" s
      ON ST_CONTAINS( TO_GEOGRAPHY(s."state_geom"), p.port_geog )
),

storms AS (       -- named North-Atlantic storm fixes (≥ 35 kt & ≥ TS)
    SELECT  h."sid",
            h."name",
            h."season",
            h."usa_wind",
            h."usa_sshs",
            ST_MAKEPOINT(h."longitude", h."latitude")        AS storm_geog,
            ST_ASTEXT(ST_MAKEPOINT(h."longitude", h."latitude")) AS storm_wkt
    FROM NOAA_PORTS.NOAA_HURRICANES."HURRICANES" h
    WHERE h."basin"     = 'NA'
      AND h."name"     <> 'NOT_NAMED'
      AND h."usa_wind" >= 35
      AND h."usa_sshs" >= 0
      AND h."longitude" IS NOT NULL
      AND h."latitude"  IS NOT NULL
)

SELECT
    ps."index_number",
    ps."port_name",
    ps."state_name",
    ARRAY_AGG( DISTINCT st."season" )              AS storm_years,
    COUNT( DISTINCT st."sid" )                     AS storm_count,
    ARRAY_AGG( DISTINCT st."name" )                AS storm_names,
    ROUND( AVG(st."usa_sshs"), 2 )                 AS avg_category,
    ROUND( AVG(st."usa_wind"), 2 )                 AS avg_wind_knots,
    MIN(ps.port_wkt)                               AS port_geometry_wkt,
    ARRAY_AGG( DISTINCT st.storm_wkt )             AS storm_geometries_wkt
FROM port_state ps
JOIN storms     st
  ON ST_DISTANCE(ps.port_geog, st.storm_geog) <= 50000   -- 50 km buffer
GROUP BY
    ps."index_number",
    ps."port_name",
    ps."state_name"
ORDER BY storm_count DESC NULLS LAST;