/*  Most-frequent Region-6585 U.S. port inside the same-state footprint 
    of named North-Atlantic tropical-storm observations (wind ≥ 35 kt)  */

WITH us_ports AS (   --  Region-6585 ports that are in the U.S.
    SELECT
        p."index_number",
        p."port_name",
        p."port_geom"
    FROM NOAA_PORTS.GEO_INTERNATIONAL_PORTS.WORLD_PORT_INDEX p
    WHERE p."region_number" = '6585'
      AND p."country"       = 'US'
      AND p."port_geom"     IS NOT NULL
),
ports_states AS (     --  Attach each port to the state polygon it lies in
    SELECT
        p."index_number",
        p."port_name",
        s."state_geom"
    FROM us_ports p
    JOIN NOAA_PORTS.GEO_US_BOUNDARIES.STATES s
      ON ST_INTERSECTS(
           TO_GEOGRAPHY(p."port_geom"),
           TO_GEOGRAPHY(s."state_geom")
         )
),
storm_points AS (     --  North-Atlantic named storm observations (≥35 kt)
    SELECT
        ST_POINT(h."longitude", h."latitude")   AS storm_geog
    FROM NOAA_PORTS.NOAA_HURRICANES.HURRICANES h
    WHERE h."basin"     = 'NA'
      AND h."usa_wind" >= 35
      AND h."name"     <> 'NOT_NAMED'
      AND h."longitude" IS NOT NULL
      AND h."latitude"  IS NOT NULL
)
SELECT
    ps."index_number"      AS "port_id",
    ps."port_name",
    COUNT(*)               AS "storm_hits"
FROM ports_states  ps
JOIN storm_points  sp
  ON ST_INTERSECTS(
       TO_GEOGRAPHY(ps."state_geom"),
       sp.storm_geog
     )
GROUP BY 1, 2
ORDER BY "storm_hits" DESC NULLS LAST
FETCH 1;