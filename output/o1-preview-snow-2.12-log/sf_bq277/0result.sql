SELECT
     p."port_name",
     COUNT(*) AS "frequency"
FROM
     "NOAA_PORTS"."GEO_INTERNATIONAL_PORTS"."WORLD_PORT_INDEX" p
JOIN
     "NOAA_PORTS"."NOAA_HURRICANES"."HURRICANES" h
ON
     ST_DISTANCE(
         ST_POINT(p."port_longitude", p."port_latitude"),
         ST_POINT(h."longitude", h."latitude")
     ) < 200000  -- Within 200 km radius
WHERE
     p."region_number" = '6585'
     AND p."country" = 'US'
     AND h."basin" = 'NA'
     AND h."wmo_wind" >= 35
     AND h."name" != 'NOT_NAMED'
GROUP BY
     p."port_name"
ORDER BY
     "frequency" DESC NULLS LAST
LIMIT 1;