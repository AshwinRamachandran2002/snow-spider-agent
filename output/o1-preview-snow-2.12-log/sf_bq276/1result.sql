SELECT
    p."port_name",
    s."state_name",
    ARRAY_TO_STRING(ARRAY_AGG(DISTINCT EXTRACT(year FROM TO_TIMESTAMP_NTZ(h."iso_time" / 1e6))), ', ') AS "storm_years",
    COUNT(DISTINCT h."sid") AS "total_storms",
    ARRAY_TO_STRING(ARRAY_AGG(DISTINCT h."name"), ', ') AS "storm_names",
    ROUND(AVG(h."usa_sshs"), 4) AS "average_category",
    ROUND(AVG(h."wmo_wind"), 4) AS "average_wind_speed",
    ST_ASWKT(ST_GEOGFROMWKB(p."port_geom")) AS "port_geometry",
    ST_ASWKT(ST_COLLECT(ST_MAKEPOINT(h."longitude", h."latitude"))) AS "storm_geometry"
FROM
    "NOAA_PORTS"."GEO_INTERNATIONAL_PORTS"."WORLD_PORT_INDEX" p
INNER JOIN
    "NOAA_PORTS"."GEO_US_BOUNDARIES"."STATES" s
    ON ST_INTERSECTS(
        ST_GEOGFROMWKB(p."port_geom"),
        ST_GEOGFROMWKB(s."state_geom")
    )
INNER JOIN
    "NOAA_PORTS"."NOAA_HURRICANES"."HURRICANES" h
    ON ST_DISTANCE(
        ST_GEOGFROMWKB(p."port_geom"),
        ST_MAKEPOINT(h."longitude", h."latitude")
    ) < 50000  -- within 50 km radius
WHERE
    p."region_number" = '6585'
    AND h."basin" = 'NA'
    AND h."name" IS NOT NULL
    AND h."name" != ''
    AND h."wmo_wind" >= 35
    AND h."usa_sshs" >= 1
GROUP BY
    p."port_name",
    s."state_name",
    p."port_geom"
ORDER BY
    p."port_name";