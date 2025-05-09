SELECT
  p."port_name",
  h."name" AS "storm_names",
  ROUND(AVG(h."usa_sshs"), 4) AS "average_category"
FROM
  NOAA_PORTS.GEO_INTERNATIONAL_PORTS.WORLD_PORT_INDEX p
JOIN
  NOAA_PORTS.GEO_US_BOUNDARIES.STATES s
  ON ST_CONTAINS(
    ST_GEOGFROMWKB(s."state_geom"),
    ST_POINT(p."port_longitude", p."port_latitude")
  )
JOIN
  NOAA_PORTS.NOAA_HURRICANES.HURRICANES h
  ON ST_DISTANCE(
    ST_POINT(p."port_longitude", p."port_latitude"),
    ST_POINT(h."longitude", h."latitude")
  ) < 200000
WHERE
  p."region_number" = '6585'
  AND p."country" = 'US'
  AND p."port_latitude" IS NOT NULL
  AND p."port_longitude" IS NOT NULL
  AND h."basin" = 'NA'
  AND h."name" IS NOT NULL
  AND h."name" != 'NOT_NAMED'
  AND h."wmo_wind" >= 35
  AND h."usa_sshs" >= 1
  AND h."usa_sshs" IS NOT NULL
GROUP BY
  p."port_name",
  h."name";