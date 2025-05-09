/*  Ports in region 6585 that lie inside U.S.-state polygons and that have been
    affected by named North-Atlantic storms (wind ≥ 35 kt, ≥ TS strength).            */
SELECT
    p."port_name"                                            AS "port_name",
    st."state_name"                                          AS "state_name",

    /* distinct storm-years (sorted) */
    ARRAY_SORT(
        ARRAY_AGG(
            DISTINCT YEAR( TO_TIMESTAMP_NTZ( h."iso_time" / 1000 ) )
        )
    )                                                        AS "storm_years",

    /* number of distinct storms */
    COUNT(DISTINCT h."sid")                                  AS "total_storms",

    /* distinct storm names (sorted) */
    ARRAY_SORT(
        ARRAY_AGG( DISTINCT h."name" )
    )                                                        AS "storm_names",

    AVG(h."usa_sshs")                                        AS "avg_storm_category",
    ROUND(AVG(h."usa_wind"),2)                               AS "avg_wind_kt",

    /* WKT for the port location */
    ST_ASWKT(
        ST_POINT( p."port_longitude", p."port_latitude" )
    )                                                        AS "port_geom_wkt",

    /* WKT for all distinct qualifying storm-center points */
    ARRAY_AGG(
        DISTINCT ST_ASWKT( ST_POINT( h."longitude", h."latitude" ) )
    )                                                        AS "storm_geoms_wkt"

FROM NOAA_PORTS.GEO_INTERNATIONAL_PORTS."WORLD_PORT_INDEX"  p
JOIN NOAA_PORTS.GEO_US_BOUNDARIES."STATES"                 st
  ON ST_WITHIN(
       ST_POINT( p."port_longitude", p."port_latitude" ),
       TO_GEOGRAPHY( st."state_geom" )
     )
JOIN NOAA_PORTS.NOAA_HURRICANES."HURRICANES"               h
  ON ST_WITHIN(
       ST_POINT( h."longitude", h."latitude" ),
       TO_GEOGRAPHY( st."state_geom" )
     )
WHERE p."region_number" = '6585'
  AND h."basin"      = 'NA'
  AND h."usa_wind"  >= 35
  AND h."usa_sshs"  >= 0
  AND h."name"      <> 'NOT_NAMED'

GROUP BY
    p."port_name",
    st."state_name",
    p."port_longitude",
    p."port_latitude"

ORDER BY
    p."port_name";