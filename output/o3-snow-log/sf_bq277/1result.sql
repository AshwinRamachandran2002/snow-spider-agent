/*  Most frequently impacted port (region 6585, U.S. ports, ≤25 km from storm center)  */
WITH region_ports AS (
    /* ports in the requested region                                         */
    SELECT  p."index_number",
            p."port_name",
            p."port_geom"
    FROM    NOAA_PORTS.GEO_INTERNATIONAL_PORTS."WORLD_PORT_INDEX"  p
    WHERE   p."region_number" = '6585'
), us_region_ports AS (
    /* keep only those ports whose point lies inside a U.S. state geometry   */
    SELECT  rp."index_number",
            rp."port_name",
            rp."port_geom"
    FROM    region_ports  rp
    JOIN    NOAA_PORTS.GEO_US_BOUNDARIES."STATES" s
           ON ST_CONTAINS(
                  TO_GEOGRAPHY(s."state_geom"),
                  TO_GEOGRAPHY(rp."port_geom")
              )
), atl_named_storm_pts AS (
    /* North-Atlantic storm points, named & ≥35 kt                           */
    SELECT  h."sid",
            h."longitude",
            h."latitude"
    FROM    NOAA_PORTS.NOAA_HURRICANES."HURRICANES"  h
    WHERE   h."basin" = 'NA'
      AND   COALESCE(h."wmo_wind", h."usa_wind") >= 35    -- ≥ 35 kt
      AND   h."name" <> 'NOT_NAMED'                       -- exclude unnamed
)
SELECT  p."port_name",
        COUNT(DISTINCT h."sid") AS "named_storm_hits"
FROM    us_region_ports          p
JOIN    atl_named_storm_pts      h
       ON ST_DISTANCE(
              TO_GEOGRAPHY(p."port_geom"),
              ST_POINT(h."longitude", h."latitude")
          ) <= 25000             -- within 25 km
GROUP BY p."port_name"
ORDER BY "named_storm_hits" DESC NULLS LAST
LIMIT 1;