/* -------------------------------------------------------------
   Corrected query: drop GEOGRAPHY from GROUP BY and rebuild it
-----------------------------------------------------------------*/
WITH us_ports AS (   -- 1. Region-6585 ports located inside a state
  SELECT
      p."index_number",
      p."port_name",
      s."state_name",
      p."port_geom"                         AS port_wkb,      -- keep WKB (BINARY)
      TO_GEOGRAPHY(p."port_geom")           AS port_geog
  FROM NOAA_PORTS.GEO_INTERNATIONAL_PORTS."WORLD_PORT_INDEX" p
  JOIN NOAA_PORTS.GEO_US_BOUNDARIES."STATES"               s
        ON ST_CONTAINS(
             TO_GEOGRAPHY(s."state_geom"),
             TO_GEOGRAPHY(p."port_geom")
           )
  WHERE p."region_number" = '6585'
),

state_storm_pts AS ( -- 2. Storm track points that satisfy filters
  SELECT
      s."state_name",
      h."sid",
      h."name"                  AS storm_name,
      h."season",
      h."usa_wind",
      h."usa_sshs",
      ST_POINT(h."longitude", h."latitude") AS storm_pt
  FROM NOAA_PORTS.NOAA_HURRICANES."HURRICANES"            h
  JOIN NOAA_PORTS.GEO_US_BOUNDARIES."STATES"              s
        ON ST_CONTAINS(
             TO_GEOGRAPHY(s."state_geom"),
             ST_POINT(h."longitude", h."latitude")
           )
  WHERE h."basin"      = 'NA'
    AND h."usa_wind"  >= 35             -- ≥ 35 kt
    AND h."usa_sshs"  >= 0              -- ≥ minimal TS
    AND h."name"      IS NOT NULL
    AND h."name"     <> 'NOT_NAMED'
)

SELECT
    p."index_number",
    p."port_name",
    p."state_name",

    /* distinct years in which qualifying storms occurred */
    ARRAY_AGG( DISTINCT CAST(ss."season" AS STRING) )            AS years_impacted,

    /* number of distinct storms */
    COUNT( DISTINCT ss."sid" )                                   AS distinct_storm_count,

    /* list of storm names */
    ARRAY_AGG( DISTINCT ss.storm_name )                          AS storm_names,

    /* average Saffir-Simpson category */
    ROUND( AVG(ss."usa_sshs"), 2 )                               AS avg_storm_category,

    /* average wind speed (kt) */
    ROUND( AVG(ss."usa_wind"), 2 )                               AS avg_wind_kts,

    /* geometries --------------------------------------------------- */
    TO_GEOGRAPHY( MIN(p.port_wkb) )                              AS port_geometry,   -- rebuild after GROUP BY
    ARRAY_AGG( DISTINCT ST_ASWKT(ss.storm_pt) )                  AS storm_point_wkts

FROM       us_ports        p
JOIN       state_storm_pts ss
      ON   ss."state_name" = p."state_name"
     AND   ST_DWITHIN(                     -- “affected” ⇒ within 30 nm
             ss.storm_pt,
             p.port_geog,
             30 * 1852                    -- metres
           )

GROUP BY
    p."index_number",
    p."port_name",
    p."state_name"

ORDER BY
    p."state_name",
    p."port_name";