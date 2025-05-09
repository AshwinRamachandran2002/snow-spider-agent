/*  U.S. ports (region 6585) intersecting state polygons that have been
    struck (≤100 km) by NAMED North-Atlantic storms with wind ≥35 kt and
    a Saffir-Simpson category ≥0.  Returns per-port summary plus geometries. */

WITH us_ports AS (       ------------------------------------------------------
    SELECT
        p."index_number",
        p."port_name",
        TO_GEOGRAPHY(p."port_geom")                    AS port_geo,
        ST_ASWKT(TO_GEOGRAPHY(p."port_geom"))          AS port_wkt,   -- text
        s."state_name"
    FROM NOAA_PORTS.GEO_INTERNATIONAL_PORTS."WORLD_PORT_INDEX" p
    JOIN NOAA_PORTS.GEO_US_BOUNDARIES."STATES"          s
      ON ST_INTERSECTS(TO_GEOGRAPHY(p."port_geom"),
                       TO_GEOGRAPHY(s."state_geom"))
    WHERE p."region_number" = '6585'
),

na_storms AS (         ---------------------------------------------------------
    SELECT  DISTINCT
        "sid",
        "name"                                          AS storm_name,
        TO_NUMBER("season")                             AS season,
        ST_MAKEPOINT("longitude","latitude")            AS storm_geo,
        ST_ASWKT(ST_MAKEPOINT("longitude","latitude"))  AS storm_wkt, -- text
        "usa_wind",
        "usa_sshs"
    FROM NOAA_PORTS.NOAA_HURRICANES."HURRICANES"
    WHERE "basin"      = 'NA'
      AND "name"      <> 'NOT_NAMED'          -- named storms only
      AND "usa_wind"  >= 35                  -- ≥35 kt
      AND "usa_sshs"  >= 0                   -- ≥TS on SSHS
      AND "longitude" IS NOT NULL
      AND "latitude"  IS NOT NULL
),

hits AS (              ---------------------------------------------------------
    SELECT
        p."port_name",
        p."state_name",
        p.port_wkt,
        s.storm_name,
        s.storm_wkt,
        s.season,
        s."usa_sshs",
        s."usa_wind"
    FROM us_ports p
    JOIN na_storms s
      ON ST_DWITHIN(p.port_geo, s.storm_geo, 100000)   -- 100 km
)

SELECT
    "port_name",
    "state_name",
    ARRAY_AGG(DISTINCT season)          AS "years_hit",
    COUNT(DISTINCT storm_name)          AS "storm_count",
    ARRAY_AGG(DISTINCT storm_name)      AS "storms",
    ROUND(AVG(DISTINCT "usa_sshs"),2)   AS "avg_category",
    ROUND(AVG(DISTINCT "usa_wind"),2)   AS "avg_wind_kt",
    port_wkt,
    ARRAY_AGG(DISTINCT storm_wkt)       AS "storm_wkts"
FROM hits
GROUP BY "port_name", "state_name", port_wkt
ORDER BY "port_name";