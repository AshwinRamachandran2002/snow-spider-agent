SELECT
    p."port_name"
FROM
    NOAA_PORTS.GEO_INTERNATIONAL_PORTS.WORLD_PORT_INDEX p
JOIN
    NOAA_PORTS.NOAA_HURRICANES.HURRICANES h
ON
    ST_DISTANCE(
        ST_MAKEPOINT(p."port_longitude", p."port_latitude"),
        ST_MAKEPOINT(h."longitude", h."latitude")
    ) <= 50000
WHERE
    p."region_number" = '6585'
    AND h."basin" = 'NA'
    AND h."wmo_wind" >= 35
    AND h."name" IS NOT NULL
    AND h."name" != 'NOT_NAMED'
    AND p."port_latitude" IS NOT NULL
    AND p."port_longitude" IS NOT NULL
    AND h."latitude" IS NOT NULL
    AND h."longitude" IS NOT NULL
GROUP BY
    p."port_name"
ORDER BY
    COUNT(*) DESC NULLS LAST
LIMIT 1;