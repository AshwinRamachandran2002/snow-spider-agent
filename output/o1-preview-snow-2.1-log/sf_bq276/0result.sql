SELECT
    p."port_name",
    LISTAGG(DISTINCT h."name", ', ') AS "storm_names",
    ROUND(AVG(h."usa_sshs"), 4) AS "average_category"
FROM
    NOAA_PORTS.GEO_INTERNATIONAL_PORTS.WORLD_PORT_INDEX p
JOIN
    NOAA_PORTS.GEO_US_BOUNDARIES.STATES s
        ON ST_Intersects(
            ST_GeographyFromWKB(p."port_geom", 4326),
            ST_GeographyFromWKB(s."state_geom", 4326)
        )
JOIN
    NOAA_PORTS.NOAA_HURRICANES.HURRICANES h
        ON ST_DISTANCE(
            ST_GEOGRAPHYFROMTEXT('POINT(' || p."port_longitude" || ' ' || p."port_latitude" || ')'),
            ST_GEOGRAPHYFROMTEXT('POINT(' || h."longitude" || ' ' || h."latitude" || ')')
        ) <= 500000  -- 500 km radius
WHERE
    p."region_number" = '6585'
    AND h."name" IS NOT NULL
    AND h."name" != 'UNNAMED'
    AND h."basin" = 'NA'  -- Adjusted basin code
    AND h."wmo_wind" >= 35
    AND h."usa_sshs" >= 0
GROUP BY
    p."port_name"
ORDER BY
    p."port_name";