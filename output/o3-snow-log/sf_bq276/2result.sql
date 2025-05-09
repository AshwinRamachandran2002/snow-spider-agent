/*  ---------------------------------------------------------------
    Ports in WPI region 6585 that
      • fall inside a U.S. state polygon
      • have been within ~60 NM (≈ 111 km) of a named North-Atlantic
        storm that carried ≥ 35 kt winds and was at least a minimal
        tropical-storm on the Saffir-Simpson scale.

    The query returns, per port:
      – port_name
      – state_name
      – ARRAY of distinct storm years (season)
      – number of distinct storms
      – ARRAY of distinct storm names
      – average (distinct) Saffir-Simpson category
      – average (distinct) wind speed (kt)
      – WKT for the port point
      – ARRAY of WKT storm–center points that met the criteria
-----------------------------------------------------------------*/
WITH
/* ---------- 1.  Ports that are in region-6585 AND inside a state */
us_ports AS (
    SELECT
        p."index_number",
        p."port_name",
        ST_GEOGFROMWKB(p."port_geom")                 AS port_geo,
        ST_ASWKT( ST_GEOGFROMWKB(p."port_geom") )     AS port_wkt,
        s."state_name"
    FROM NOAA_PORTS.GEO_INTERNATIONAL_PORTS."WORLD_PORT_INDEX"  p
    JOIN NOAA_PORTS.GEO_US_BOUNDARIES."STATES"        s
          ON ST_CONTAINS( ST_GEOGFROMWKB(s."state_geom"),
                          ST_GEOGFROMWKB(p."port_geom") )
    WHERE p."region_number" = '6585'
          AND p."country"   = 'US'
),

/* ---------- 2.  Storm observations that satisfy intensity filters */
atl_storm_pts AS (
    SELECT
        h."sid",
        h."name",
        TO_NUMBER(h."season")                         AS storm_year,
        h."usa_sshs"                                  AS cat,
        COALESCE(h."usa_wind", h."wmo_wind")          AS wind_kt,
        ST_POINT(h."longitude", h."latitude")         AS storm_geo,
        ST_ASWKT( ST_POINT(h."longitude", h."latitude") ) AS storm_wkt
    FROM NOAA_PORTS.NOAA_HURRICANES."HURRICANES" h
    WHERE h."basin" = 'NA'
          AND COALESCE(h."usa_wind", h."wmo_wind") >= 35      -- ≥35 kt
          AND h."usa_sshs" >= 0                               -- ≥ TS
          AND h."name" NOT ILIKE '%not%named%'
),

/* ---------- 3.  Pair ports with storms within 60 NM (≈ 111 km) */
port_storm_hits AS (
    SELECT
        p."index_number",
        p."port_name",
        p."state_name",
        p.port_wkt,
        s."sid",
        s."name"                        AS storm_name,
        s.storm_year,
        s.cat,
        s.wind_kt,
        s.storm_wkt
    FROM us_ports p
    JOIN atl_storm_pts s
          ON ST_DWITHIN( p.port_geo, s.storm_geo, 111000 )    -- metres
)

/* ---------- 4.  Aggregate per port -------------------------------- */
SELECT
    ps."port_name",
    ps."state_name",
    ARRAY_AGG( DISTINCT ps.storm_year )                     AS storm_years,
    COUNT( DISTINCT ps."sid" )                              AS storm_count,
    ARRAY_AGG( DISTINCT ps.storm_name )                     AS storm_names,
    AVG( DISTINCT ps.cat )                                 AS avg_category,
    AVG( DISTINCT ps.wind_kt )                             AS avg_wind_kt,
    MAX( ps.port_wkt )                                     AS port_wkt,
    ARRAY_AGG( DISTINCT ps.storm_wkt )                     AS storm_wkts
FROM port_storm_hits ps
GROUP BY
    ps."port_name",
    ps."state_name"
ORDER BY
    ps."state_name",
    ps."port_name";