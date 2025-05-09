/*  Find the single port in region 6585 that:
      • lies inside a U.S. state polygon
      • falls most often within a 1-degree lat-/lon box of named North-Atlantic
        tropical-storm points (USA wind ≥ 35 kt, name not “NOT_NAMED”)
*/
WITH us_region_ports AS (
    SELECT
        p."index_number",
        p."port_name",
        p."port_latitude",
        p."port_longitude",
        p."port_geom"
    FROM NOAA_PORTS.GEO_INTERNATIONAL_PORTS.WORLD_PORT_INDEX p
    WHERE p."region_number" = '6585'
      AND p."country"       = 'US'
),
ports_in_states AS (      -- keep only ports whose point lies within a state boundary
    SELECT up.*
    FROM   us_region_ports  up
    JOIN   NOAA_PORTS.GEO_US_BOUNDARIES.STATES s
           ON ST_CONTAINS(
                 TO_GEOGRAPHY(s."state_geom"),
                 TO_GEOGRAPHY(up."port_geom")
              )
),
atl_storm_pts AS (        -- North-Atlantic, ≥35 kt, real name
    SELECT
        h."latitude",
        h."longitude"
    FROM NOAA_PORTS.NOAA_HURRICANES.HURRICANES h
    WHERE h."basin"     = 'NA'
      AND h."usa_wind" >= 35
      AND h."name"     <> 'NOT_NAMED'
)
SELECT
    p."port_name",
    COUNT(*) AS storm_point_hits
FROM   ports_in_states  p
JOIN   atl_storm_pts    h
       ON ABS(h."latitude"  - p."port_latitude")  < 1   -- ≈ 60 nm lat band
      AND ABS(h."longitude" - p."port_longitude") < 1   -- ≈ 60 nm lon band
GROUP BY p."port_name"
ORDER BY storm_point_hits DESC NULLS LAST
LIMIT 1;