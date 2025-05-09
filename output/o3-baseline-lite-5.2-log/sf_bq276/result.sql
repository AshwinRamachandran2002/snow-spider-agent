WITH
/* --- region‑specific ports --------------------------------------------- */
ports AS (
    SELECT
        p."index_number",
        p."port_name",
        p."port_geom",                         -- original WKB
        TO_GEOGRAPHY(p."port_geom") AS port_geog
    FROM NOAA_PORTS.GEO_INTERNATIONAL_PORTS."WORLD_PORT_INDEX" p
    WHERE p."region_number" = '6585'           -- << requested region >>
),
/* --- keep only ports that fall inside a U.S. state ---------------------- */
us_ports AS (
    SELECT
        p.*,
        s."state_name"
    FROM ports p
    JOIN NOAA_PORTS.GEO_US_BOUNDARIES."STATES"  s
          ON ST_WITHIN(p.port_geog , TO_GEOGRAPHY(s."state_geom"))
),
/* --- North‑Atlantic storms >=35 kt & >=TS strength ---------------------- */
atl_storm_pts AS (
    SELECT
        h."sid",
        h."name",
        h."usa_wind",
        h."usa_sshs",
        h."iso_time",
        h."longitude",
        h."latitude",
        ST_MAKEPOINT(h."longitude",h."latitude") AS storm_geog
    FROM NOAA_PORTS.NOAA_HURRICANES."HURRICANES" h
    WHERE h."basin"        = 'NA'      -- North Atlantic basin
      AND h."usa_wind"    >= 35        -- ≥ 35 kt  (≥ minimal TS)
      AND h."usa_sshs"    >= 0         -- Saffir‑Simpson TS‑or‑higher
      AND h."longitude" IS NOT NULL
      AND h."latitude"  IS NOT NULL
)
/* =================== final aggregation ================================== */
SELECT
    up."port_name"                                         AS port_name ,
    up."state_name"                                        AS state_name,
    LISTAGG( DISTINCT YEAR( TO_TIMESTAMP_NTZ(st."iso_time"/1000) )
             ,',' )                                        AS years ,
    COUNT( DISTINCT st."sid")                              AS storm_count ,
    LISTAGG( DISTINCT st."name" , ',' )                    AS storm_names ,
    ROUND( AVG(st."usa_sshs")     ,2)                      AS avg_category ,
    ROUND( AVG(st."usa_wind")     ,2)                      AS avg_wind_knots ,
    up."port_geom"                                         AS port_geom ,      -- WKB
    ST_ASWKB( ST_UNION_AGG( st.storm_geog ) )              AS storms_geom      -- WKB
FROM   us_ports        up
JOIN   atl_storm_pts   st
       ON ST_DISTANCE( up.port_geog , st.storm_geog ) <= 111000   -- ≤ 60 NM ≈ 111 km
GROUP  BY
       up."port_name",
       up."state_name",
       up."port_geom"
ORDER BY
       up."port_name";