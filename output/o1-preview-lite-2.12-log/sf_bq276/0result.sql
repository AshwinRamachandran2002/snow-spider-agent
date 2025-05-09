SELECT 
    p."port_name", 
    s."state_name",
    LISTAGG(DISTINCT h."season", ', ') AS "storm_years",
    COUNT(DISTINCT h."name") AS "total_storms",
    LISTAGG(DISTINCT h."name", ', ') AS "storm_names",
    ROUND(AVG(h."usa_sshs"), 4) AS "average_category",
    ROUND(AVG(h."wmo_wind"), 4) AS "average_wind_speed",
    ST_ASWKT(ST_GEOGFROMWKB(p."port_geom")) AS "port_geometry",
    ST_ASWKT(ST_UNION_AGG(ST_MAKEPOINT(h."longitude", h."latitude"))) AS "storm_geometry"
FROM "NOAA_PORTS"."GEO_INTERNATIONAL_PORTS"."WORLD_PORT_INDEX" p
JOIN "NOAA_PORTS"."GEO_US_BOUNDARIES"."STATES" s
    ON ST_CONTAINS(ST_GEOGFROMWKB(s."state_geom"), ST_GEOGFROMWKB(p."port_geom"))
JOIN "NOAA_PORTS"."NOAA_HURRICANES"."HURRICANES" h
    ON ST_DISTANCE(ST_GEOGFROMWKB(p."port_geom"), ST_MAKEPOINT(h."longitude", h."latitude")) <= 50000
WHERE 
    p."region_number" = '6585' 
    AND p."country" = 'US'
    AND h."basin" = 'NA' 
    AND h."wmo_wind" >= 35 
    AND h."wmo_wind" IS NOT NULL
    AND h."usa_sshs" >= 1
    AND h."usa_sshs" IS NOT NULL
    AND h."usa_sshs" <> -4
    AND h."name" IS NOT NULL
    AND h."name" <> 'NOT_NAMED'
GROUP BY p."port_name", s."state_name", p."port_geom";