SELECT p."port_name", COUNT(*) AS "frequency"
FROM NOAA_PORTS.GEO_INTERNATIONAL_PORTS.WORLD_PORT_INDEX p
JOIN NOAA_PORTS.GEO_US_BOUNDARIES.STATES s
  ON ST_CONTAINS(ST_GEOGRAPHYFROMWKB(s."state_geom"), ST_POINT(p."port_longitude", p."port_latitude"))
JOIN NOAA_PORTS.NOAA_HURRICANES.HURRICANES h
  ON ST_DISTANCE(
       ST_POINT(p."port_longitude", p."port_latitude"),
       ST_POINT(h."longitude", h."latitude")
     ) <= 100000  -- Distance in meters (100 km)
WHERE p."region_number" = '6585'
  AND h."basin" = 'NA'
  AND h."wmo_wind" >= 35
  AND h."name" IS NOT NULL AND TRIM(UPPER(h."name")) != 'NOT_NAMED'
GROUP BY p."port_name"
ORDER BY "frequency" DESC NULLS LAST
LIMIT 1;