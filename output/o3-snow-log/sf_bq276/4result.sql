/*  U.S. ports in WPI region 6585 that were within ±1° of any
    named North-Atlantic storm with ≥35-kt winds (TS or stronger).
    Returns summary stats plus geometries for the port and
    the set of nearby storm-track points.                             */

WITH ports_us AS (                   -- 1.  U.S. ports in region 6585
    SELECT
        p."index_number",
        p."port_name",
        p."port_latitude",
        p."port_longitude",
        p."port_geom",
        st."state_name"
    FROM NOAA_PORTS.GEO_INTERNATIONAL_PORTS.WORLD_PORT_INDEX p
    JOIN NOAA_PORTS.GEO_US_BOUNDARIES.STATES st
      ON ST_CONTAINS(
             TO_GEOGRAPHY(st."state_geom"),
             TO_GEOGRAPHY(p."port_geom")
         )
    WHERE p."region_number" = '6585'      -- Mid-Atlantic & New-England
      AND p."country"       = 'US'
),

storms AS (                          -- 2.  Named N-Atlantic storms ≥ TS
    SELECT
        "sid",
        "name",
        "usa_sshs",
        "usa_wind",
        "latitude",
        "longitude",
        "iso_time"
    FROM NOAA_PORTS.NOAA_HURRICANES.HURRICANES
    WHERE "basin"     = 'NA'
      AND "name"     IS NOT NULL
      AND "usa_wind" >= 35            -- 35-kt threshold
      AND "usa_sshs" >= 0             -- TS or stronger
)

SELECT
    p."port_name"                                                     AS port_name,
    p."state_name"                                                    AS state_name,
    LISTAGG(
        DISTINCT YEAR( TO_TIMESTAMP_NTZ( s."iso_time" / 1000 ) )::TEXT,
        ', '
    )                                                                 AS storm_years,
    COUNT( DISTINCT s."sid" )                                         AS total_distinct_storms,
    LISTAGG( DISTINCT s."name", ', ' )                                AS storm_names,
    ROUND( AVG( s."usa_sshs" ), 2 )                                   AS avg_storm_category,
    ROUND( AVG( s."usa_wind" ), 2 )                                   AS avg_wind_speed_knots,
    TO_GEOGRAPHY( p."port_geom" )                                     AS port_geometry,
    ST_UNION_AGG( ST_POINT( s."longitude", s."latitude" ) )           AS storms_geometry
FROM ports_us p
JOIN storms  s
  ON ABS( s."latitude"  - p."port_latitude"  ) <= 1
 AND ABS( s."longitude" - p."port_longitude" ) <= 1
GROUP BY
    p."port_name",
    p."state_name",
    p."port_geom"
ORDER BY
    p."state_name",
    p."port_name";