WITH ports AS (  -- 1.  U.S. ports in region 6585
    SELECT
        "port_name",
        "port_geom"
    FROM NOAA_PORTS.GEO_INTERNATIONAL_PORTS.WORLD_PORT_INDEX
    WHERE "region_number" = '6585'
      AND "country"       = 'US'
      AND "port_geom"    IS NOT NULL
),

states AS (      -- 2.  State polygons
    SELECT
        "state_name",
        "state_geom"
    FROM NOAA_PORTS.GEO_US_BOUNDARIES.STATES
),

port_state AS (  -- 3.  Determine state for each port
    SELECT
        p."port_name",
        p."port_geom",
        s."state_name",
        s."state_geom"
    FROM ports  p
    JOIN states s
      ON ST_WITHIN(
           TO_GEOGRAPHY(p."port_geom"),
           TO_GEOGRAPHY(s."state_geom")
         )
),

storms AS (      -- 4.  North‑Atlantic storms ≥35 kt & ≥TS strength
    SELECT
        "sid",
        "name",
        "season",
        "usa_sshs",                     -- –1 TD, 0 TS, 1–5 HU
        "usa_wind",                     -- kt
        ST_MAKEPOINT("longitude", "latitude") AS storm_point
    FROM NOAA_PORTS.NOAA_HURRICANES.HURRICANES
    WHERE "basin"      = 'NA'
      AND "usa_wind"  >= 35
      AND "usa_sshs"  >= 0
      AND "name"       IS NOT NULL
      AND UPPER("name") NOT LIKE '%NOT_NAMED%'
      AND "longitude" IS NOT NULL
      AND "latitude"  IS NOT NULL
)

-- 5.  Join ports to storms via shared‑state intersection
SELECT
    ps."port_name"                              AS "PORT",
    ps."state_name"                             AS "STATE",
    ARRAY_AGG(DISTINCT st."season")             AS "STORM_YEARS",
    COUNT(DISTINCT st."sid")                    AS "DISTINCT_STORM_COUNT",
    ARRAY_AGG(DISTINCT st."name")               AS "STORM_NAMES",
    AVG(st."usa_sshs")                          AS "AVG_STORM_CATEGORY",
    AVG(st."usa_wind")                          AS "AVG_WIND_KT",
    TO_GEOGRAPHY(ps."port_geom")                AS "PORT_GEOMETRY",
    ST_UNION_AGG(st.storm_point)                AS "STORMS_GEOMETRY"
FROM port_state ps
JOIN storms st
  ON ST_WITHIN(st.storm_point, TO_GEOGRAPHY(ps."state_geom"))
GROUP BY
    ps."port_name",
    ps."state_name",
    ps."port_geom";