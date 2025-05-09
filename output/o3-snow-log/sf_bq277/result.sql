WITH us_ports AS (
    -- Region-6585 ports that fall inside any U.S. state polygon
    SELECT
        p."index_number",
        p."port_name",
        TO_GEOGRAPHY(p."port_geom") AS port_geog
    FROM NOAA_PORTS.GEO_INTERNATIONAL_PORTS.WORLD_PORT_INDEX p
    JOIN NOAA_PORTS.GEO_US_BOUNDARIES.STATES s
      ON ST_CONTAINS(
           TO_GEOGRAPHY(s."state_geom"),
           TO_GEOGRAPHY(p."port_geom")
         )
    WHERE p."region_number" = '6585'
),
storms AS (
    -- Distinct named North-Atlantic storm points (≥ 35 kt, excluding “NOT_NAMED”)
    SELECT DISTINCT
        h."sid",
        ST_MAKEPOINT(h."longitude", h."latitude") AS storm_geog
    FROM NOAA_PORTS.NOAA_HURRICANES.HURRICANES h
    WHERE h."basin"      = 'NA'
      AND h."usa_wind"  >= 35
      AND h."name"      <> 'NOT_NAMED'
)
SELECT
    u."port_name",
    COUNT(DISTINCT s."sid") AS named_storm_hits
FROM us_ports u
JOIN storms  s
  ON ST_DWITHIN(u.port_geog, s.storm_geog, 30000)  -- 30-km proximity
GROUP BY u."port_name"
ORDER BY named_storm_hits DESC NULLS LAST
LIMIT 1;