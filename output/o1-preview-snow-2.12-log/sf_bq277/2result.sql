SELECT
  p."port_name",
  COUNT(*) AS "frequency"
FROM
  "NOAA_PORTS"."GEO_INTERNATIONAL_PORTS"."WORLD_PORT_INDEX" p
JOIN
  "NOAA_PORTS"."GEO_US_BOUNDARIES"."STATES" s
ON
  ST_Contains(
    ST_GeogFromWKB(s."state_geom"),
    ST_MakePoint(p."port_longitude", p."port_latitude")
  )
JOIN
  "NOAA_PORTS"."NOAA_HURRICANES"."HURRICANES" h
ON
  ST_Distance(
    ST_MakePoint(p."port_longitude", p."port_latitude"),
    ST_MakePoint(h."longitude", h."latitude")
  ) < 50000
WHERE
  p."region_number" = '6585' AND
  UPPER(h."basin") = 'NA' AND
  h."wmo_wind" >= 35 AND
  UPPER(h."name") != 'NOT_NAMED'
GROUP BY
  p."port_name"
ORDER BY
  "frequency" DESC NULLS LAST
LIMIT 1;