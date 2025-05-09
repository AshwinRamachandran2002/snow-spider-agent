/* Port in region 6585 (inside a U.S. state) most often intersected
   by named North-Atlantic storms (wind ≥ 35 kt, excluding “NOT_NAMED”)
   within a 30-nautical-mile (55 560 m) radius                         */

WITH us_ports AS (
    SELECT
        p."index_number",
        p."port_name",
        ST_POINT(p."port_longitude", p."port_latitude") AS port_geog
    FROM NOAA_PORTS.GEO_INTERNATIONAL_PORTS.WORLD_PORT_INDEX  p
    JOIN NOAA_PORTS.GEO_US_BOUNDARIES.STATES                  s
      ON ST_CONTAINS(
             TO_GEOGRAPHY(s."state_geom"),
             ST_POINT(p."port_longitude", p."port_latitude")
         )
    WHERE p."region_number" = '6585'
),
storm_fixes AS (
    SELECT
        ST_POINT(h."longitude", h."latitude") AS storm_geog
    FROM NOAA_PORTS.NOAA_HURRICANES.HURRICANES h
    WHERE h."basin"    = 'NA'
      AND h."usa_wind" >= 35
      AND UPPER(h."name") <> 'NOT_NAMED'
)

SELECT
    p."port_name",
    COUNT(*) AS "total_named_storm_hits"
FROM   us_ports  p
JOIN   storm_fixes s
  ON   ST_DISTANCE(p.port_geog, s.storm_geog) <= 55560   -- 30 NM
GROUP BY p."port_name"
ORDER BY "total_named_storm_hits" DESC NULLS LAST
LIMIT 1;