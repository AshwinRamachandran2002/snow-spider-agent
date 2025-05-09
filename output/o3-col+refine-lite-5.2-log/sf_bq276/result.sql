/*  Ports in region 6585 (U.S. only) that were struck (≤ 50 km)
    by NAMED North‑Atlantic storms ≥ 35 kt (SSHS ≥ 0).

    Per‑port summary with geometries returned as WKT.            */

WITH ports AS (                      -- all ports in region 6585
    SELECT
        p."index_number",
        p."port_name",
        p."port_geom"
    FROM NOAA_PORTS.GEO_INTERNATIONAL_PORTS."WORLD_PORT_INDEX" p
    WHERE p."region_number" = '6585'
),
us_ports AS (                        -- ports that fall inside a U.S. state
    SELECT
        pr."index_number",
        pr."port_name",
        st."state_name",
        pr."port_geom"
    FROM ports pr
    JOIN NOAA_PORTS.GEO_US_BOUNDARIES."STATES" st
      ON ST_WITHIN(
             TO_GEOGRAPHY(pr."port_geom"),
             TO_GEOGRAPHY(st."state_geom")
         )
),
storm_fixes AS (                     -- NA named storms ≥ 35 kt & SSHS ≥ 0
    SELECT
        h."sid",
        h."name"        AS "storm_name",
        h."season",
        h."usa_wind",
        h."usa_sshs",
        ST_POINT(h."longitude", h."latitude") AS storm_geom
    FROM NOAA_PORTS.NOAA_HURRICANES."HURRICANES" h
    WHERE h."basin"     = 'NA'
      AND h."usa_wind" >= 35
      AND h."usa_sshs" >= 0
      AND h."name"     <> 'NOT_NAMED'
),
hits AS (                            -- storm fixes within 50 km of port
    SELECT
        p."index_number",
        p."port_name",
        p."state_name",
        s."sid",
        s."storm_name",
        s."season",
        s."usa_wind",
        s."usa_sshs",
        s.storm_geom
    FROM us_ports p
    JOIN storm_fixes s
      ON ST_DISTANCE(
             TO_GEOGRAPHY(p."port_geom"),
             s.storm_geom
         ) <= 50000                  -- 50 km
)
SELECT
    p."port_name",
    p."state_name",
    ARRAY_AGG(DISTINCT h."season")                AS "seasons",
    COUNT(DISTINCT h."sid")                       AS "num_storms",
    ARRAY_AGG(DISTINCT h."storm_name")            AS "storm_names",
    ROUND(AVG(h."usa_sshs"), 2)                   AS "avg_category",
    ROUND(AVG(h."usa_wind"), 2)                   AS "avg_wind_kt",
    MAX(ST_ASWKT(TO_GEOGRAPHY(p."port_geom")))    AS "port_geom_wkt",
    ARRAY_AGG(DISTINCT ST_ASWKT(h.storm_geom))    AS "storm_geoms_wkt"
FROM us_ports p
JOIN hits h
  ON p."index_number" = h."index_number"
GROUP BY
    p."port_name",
    p."state_name"
ORDER BY
    p."state_name",
    p."port_name";