/* -----------------------------------------------------------
   Ports in Region 6585 (U.S.) that have experienced named
   North-Atlantic storms (≥35 kt wind, ≥TS strength) within
   60 km.  Returns storm statistics plus geometries.
------------------------------------------------------------ */
WITH us_ports AS (              -- 1) eligible U.S. ports
    SELECT
        p."index_number",
        p."port_name",
        st."state_name",
        TO_GEOGRAPHY(p."port_geom") AS port_geog
    FROM NOAA_PORTS.GEO_INTERNATIONAL_PORTS."WORLD_PORT_INDEX"  p
    JOIN NOAA_PORTS.GEO_US_BOUNDARIES."STATES"                  st
         ON ST_CONTAINS(
                TO_GEOGRAPHY(st."state_geom"),
                TO_GEOGRAPHY(p."port_geom")
            )
    WHERE p."region_number" = '6585'
      AND p."country"       = 'US'
),
atl_storms AS (                 -- 2) qualified storm fixes
    SELECT
        h."sid",
        h."season",
        h."name"                               AS storm_name,
        h."usa_wind",
        h."usa_sshs",
        TO_GEOGRAPHY(
            'POINT(' || TO_CHAR(h."longitude") || ' ' || TO_CHAR(h."latitude") || ')'
        )                                       AS storm_geog
    FROM NOAA_PORTS.NOAA_HURRICANES."HURRICANES" h
    WHERE h."basin"     = 'NA'
      AND h."usa_wind" >= 35
      AND h."usa_sshs" >= 0
      AND h."name" IS NOT NULL
      AND h."name" NOT ILIKE 'NOT_NAMED'
),
impacts AS (                    -- 3) storm-to-port matches (≤ 60 km)
    SELECT
        p."index_number",
        ARRAY_AGG(DISTINCT s."season")       AS storm_years,
        COUNT(DISTINCT s."sid")              AS distinct_storm_count,
        ARRAY_AGG(DISTINCT s.storm_name)     AS storm_names,
        AVG(s."usa_sshs")                    AS avg_category,
        AVG(s."usa_wind")                    AS avg_wind_kt,
        ST_UNION_AGG(s.storm_geog)           AS storms_geometry
    FROM   us_ports  p
    JOIN   atl_storms s
           ON ST_DISTANCE(p.port_geog, s.storm_geog) <= 60000   -- 60 km
    GROUP  BY p."index_number"
)
/* 4) combine statistics with port attributes & geometry */
SELECT
    p."index_number",
    p."port_name",
    p."state_name",
    i.storm_years,
    i.distinct_storm_count,
    i.storm_names,
    i.avg_category,
    i.avg_wind_kt,
    p.port_geog          AS port_geometry,
    i.storms_geometry
FROM   us_ports p
JOIN   impacts  i
       ON p."index_number" = i."index_number"
ORDER  BY p."port_name";