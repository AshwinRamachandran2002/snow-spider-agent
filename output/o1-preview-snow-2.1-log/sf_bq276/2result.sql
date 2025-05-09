WITH ports AS (
  SELECT
    p."port_name",
    p."port_latitude",
    p."port_longitude",
    ST_GEOGFROMWKT('POINT(' || p."port_longitude" || ' ' || p."port_latitude" || ')') AS "port_geom"
  FROM "NOAA_PORTS"."GEO_INTERNATIONAL_PORTS"."WORLD_PORT_INDEX" AS p
  WHERE p."region_number" = '6585' AND p."country" = 'US'
),
ports_in_states AS (
  SELECT p."port_name", p."port_geom"
  FROM ports AS p
  JOIN "NOAA_PORTS"."GEO_US_BOUNDARIES"."STATES" AS s
    ON ST_CONTAINS(ST_GEOGFROMWKB(s."state_geom"), p."port_geom")
),
storms AS (
  SELECT DISTINCT
    h."sid",
    h."name",
    h."usa_sshs",
    ST_GEOGFROMWKT('POINT(' || h."longitude" || ' ' || h."latitude" || ')') AS "storm_point"
  FROM "NOAA_PORTS"."NOAA_HURRICANES"."HURRICANES" AS h
  WHERE h."basin" = 'NA'
    AND h."wmo_wind" >= 35
    AND h."usa_sshs" >= 1
    AND h."name" IS NOT NULL
    AND TRIM(h."name") != ''
    AND UPPER(TRIM(h."name")) != 'NOT_NAMED'
),
port_storm AS (
  SELECT DISTINCT p."port_name", s."name" AS "storm_name", s."usa_sshs"
  FROM ports_in_states AS p
  JOIN storms AS s
    ON ST_DISTANCE(p."port_geom", s."storm_point") <= 100000  -- Distance in meters (100 km)
)
SELECT
  "port_name",
  LISTAGG(DISTINCT "storm_name", ', ') WITHIN GROUP (ORDER BY "storm_name") AS "storm_names",
  ROUND(AVG("usa_sshs"), 4) AS "average_category"
FROM port_storm
GROUP BY "port_name"
ORDER BY "port_name";