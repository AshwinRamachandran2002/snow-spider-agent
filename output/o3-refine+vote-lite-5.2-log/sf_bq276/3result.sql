/*---------------------------------------------------------------------------
  Ports in region 6585 (U.S. only) that intersect a U.S. STATE boundary and
  are within 185 km of any NAMED North‑Atlantic storm whose wind ≥ 35 kt
  and USA_SSHS ≥ 0.  Returns summary information and geometries.
---------------------------------------------------------------------------*/
WITH
/* ------------ ports (cast to GEOGRAPHY for spatial tests) --------------- */
ports AS (
    SELECT
        p."index_number",
        p."port_name",
        TO_GEOGRAPHY(p."port_geom")           AS port_geog,          -- GEOGRAPHY
        p."port_geom"                         AS port_wkb,           -- original WKB
        s."state_name"
    FROM NOAA_PORTS.GEO_INTERNATIONAL_PORTS."WORLD_PORT_INDEX"  p
    JOIN NOAA_PORTS.GEO_US_BOUNDARIES."STATES"                 s
      ON ST_INTERSECTS(
             TO_GEOGRAPHY(p."port_geom"),
             TO_GEOGRAPHY(s."state_geom")
         )
    WHERE p."region_number" = '6585'
      AND p."country"       = 'US'
),
/* ------------ storms (North‑Atlantic, named, ≥TS strength) -------------- */
storms AS (
    SELECT
        st."sid",
        st."season"       ::INT                  AS storm_year,
        st."name"                             AS storm_name,
        st."usa_sshs"     ::FLOAT              AS cat,
        st."usa_wind"     ::FLOAT              AS wind_kt,
        ST_MAKEPOINT(st."longitude", st."latitude") AS storm_geog
    FROM NOAA_PORTS.NOAA_HURRICANES."HURRICANES" st
    WHERE st."basin"     = 'NA'
      AND st."usa_wind" >= 35
      AND st."usa_sshs" >= 0
      AND UPPER(st."name") NOT LIKE 'NOT_NAMED%'
      AND st."longitude" IS NOT NULL
      AND st."latitude"  IS NOT NULL
),
/* ------------ storm‑port matches (≤185 km) ------------------------------ */
encounters AS (
    SELECT
        p."index_number",
        p."port_name",
        p."state_name",
        p.port_wkb,
        s."sid",
        s.storm_year,
        s.storm_name,
        s.cat,
        s.wind_kt,
        s.storm_geog
    FROM ports  p
    JOIN storms s
      ON ST_DISTANCE(p.port_geog, s.storm_geog) <= 185000  -- 185 km
)
/* ------------ final aggregation ---------------------------------------- */
SELECT
    e."port_name"                                                                           AS "PORT_NAME",
    e."state_name"                                                                          AS "STATE_NAME",
    LISTAGG(DISTINCT e.storm_year, ', ')        WITHIN GROUP (ORDER BY e.storm_year)        AS "YEARS",
    COUNT(DISTINCT e."sid")                                                                  AS "STORM_COUNT",
    LISTAGG(DISTINCT e.storm_name, ', ')       WITHIN GROUP (ORDER BY e.storm_name)         AS "STORM_NAMES",
    ROUND(AVG(e.cat),      2)                                                                AS "AVG_CATEGORY",
    ROUND(AVG(e.wind_kt),  2)                                                                AS "AVG_WIND_KT",
    e.port_wkb                                                                               AS "PORT_GEOM_WKB",
    ST_UNION_AGG(e.storm_geog)                                                               AS "STORMS_GEOM"
FROM encounters e
GROUP BY
    e."port_name",
    e."state_name",
    e.port_wkb
ORDER BY
    e."port_name";