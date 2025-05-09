/*  Port in region 6585 that lies inside a U.S. state
    and is associated with the greatest number of *named*
    North-Atlantic tropical-storm points (wind ≥35 kt).   */

WITH port_states AS (   -- 6585 ports tagged with their containing U.S. state
    SELECT
        p."index_number",
        p."port_name",
        s."state"
    FROM NOAA_PORTS.GEO_INTERNATIONAL_PORTS."WORLD_PORT_INDEX" p
    JOIN NOAA_PORTS.GEO_US_BOUNDARIES."STATES"                s
      ON ST_CONTAINS(
             TO_GEOGRAPHY(s."state_geom"),
             TO_GEOGRAPHY(p."port_geom")
         )
    WHERE p."region_number" = '6585'
),
state_storms AS (       -- distinct named-storm SIDs that intersect each state
    SELECT DISTINCT
           st."sid",
           s."state"
    FROM NOAA_PORTS.GEO_US_BOUNDARIES."STATES" s
    JOIN (
        SELECT
            "sid",
            TO_GEOGRAPHY(ST_POINT("longitude","latitude")) AS "storm_pt"
        FROM NOAA_PORTS.NOAA_HURRICANES."HURRICANES"
        WHERE "basin"     = 'NA'
          AND "usa_wind" >= 35          -- wind ≥35 kt
          AND "name"     <> 'NOT_NAMED' -- exclude unnamed systems
          AND "longitude" IS NOT NULL   -- ensure valid point
          AND "latitude"  IS NOT NULL
    ) st
      ON ST_CONTAINS( TO_GEOGRAPHY(s."state_geom"), st."storm_pt")
)

SELECT
       ps."index_number",
       ps."port_name",
       ps."state",
       COUNT(DISTINCT ss."sid") AS "named_storm_count"
FROM   port_states  ps
JOIN   state_storms ss
       ON ps."state" = ss."state"
GROUP  BY
       ps."index_number",
       ps."port_name",
       ps."state"
ORDER  BY
       "named_storm_count" DESC NULLS LAST,   -- highest count first
       ps."index_number"      ASC            -- deterministic tie-break
LIMIT 1;