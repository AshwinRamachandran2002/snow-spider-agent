WITH region_ports AS (   -- ➊ US ports that belong to region 6585 and sit inside a State polygon
    SELECT
        p."index_number",
        p."port_name",
        TO_GEOGRAPHY(p."port_geom")                         AS port_geog
    FROM NOAA_PORTS.GEO_INTERNATIONAL_PORTS.WORLD_PORT_INDEX  p
    JOIN NOAA_PORTS.GEO_US_BOUNDARIES.STATES                 s
      ON ST_CONTAINS( TO_GEOGRAPHY(s."state_geom"), TO_GEOGRAPHY(p."port_geom") )
    WHERE p."region_number" = '6585'
      AND p."country"       = 'US'
),

storm_pts AS (          -- ➋ every named N-Atlantic storm point ≥35 kt
    SELECT
        ST_POINT("longitude","latitude")  AS storm_geog
    FROM NOAA_PORTS.NOAA_HURRICANES.HURRICANES
    WHERE "basin"      = 'NA'
      AND "usa_wind"  >= 35
      AND "name"      <> 'NOT_NAMED'
      AND "longitude" IS NOT NULL
      AND "latitude"  IS NOT NULL
)

-- ➌ count how many storm points fall within 50 nmi (~92 600 m) of each port
SELECT
    rp."index_number",
    rp."port_name",
    COUNT(*) AS storm_point_hits
FROM            region_ports  rp
JOIN            storm_pts     sp
  ON ST_DISTANCE(rp.port_geog, sp.storm_geog) <= 92600   -- 50 nautical miles buffer
GROUP BY
    rp."index_number",
    rp."port_name"
ORDER BY
    storm_point_hits DESC NULLS LAST
LIMIT 1;