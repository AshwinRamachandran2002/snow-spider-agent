WITH us_ports AS (
    /* Region-6585 ports that lie inside a U.S. state boundary */
    SELECT 
        p."index_number",
        p."port_name",
        TO_GEOGRAPHY(p."port_geom") AS port_geog
    FROM NOAA_PORTS.GEO_INTERNATIONAL_PORTS.WORLD_PORT_INDEX p
    JOIN NOAA_PORTS.GEO_US_BOUNDARIES.STATES s
      ON ST_WITHIN(TO_GEOGRAPHY(p."port_geom"), TO_GEOGRAPHY(s."state_geom"))
    WHERE p."region_number" = '6585'
      AND p."country"       = 'US'
),
named_storm_pts AS (
    /* North-Atlantic named storms with ≥ 35-kt wind */
    SELECT
        h."sid",
        ST_POINT(h."longitude", h."latitude") AS storm_geog
    FROM NOAA_PORTS.NOAA_HURRICANES.HURRICANES h
    WHERE h."basin"     = 'NA'
      AND h."usa_wind"  >= 35
      AND h."name"     <> 'NOT_NAMED'
)
SELECT
    p."port_name"
FROM us_ports          p
JOIN named_storm_pts   s
  ON ST_DWITHIN(p.port_geog, s.storm_geog, 10000)      -- 10 km (~5.4 nm) buffer
GROUP BY p."port_name"
ORDER BY COUNT(DISTINCT s."sid") DESC NULLS LAST
LIMIT 1;