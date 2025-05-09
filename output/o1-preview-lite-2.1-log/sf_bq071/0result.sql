SELECT z."zip_code", COUNT(DISTINCT h."sid") AS "number_of_occurrences"
FROM "NOAA_DATA_PLUS"."NOAA_HURRICANES"."HURRICANES" h
JOIN "NOAA_DATA_PLUS"."GEO_US_BOUNDARIES"."ZIP_CODES" z
ON ST_WITHIN(
    ST_POINT(h."usa_longitude", h."usa_latitude"),
    ST_GEOGFROMWKB(z."zip_code_geom")
)
WHERE
    h."name" IS NOT NULL AND h."name" != 'NOT_NAMED'
    AND h."usa_latitude" IS NOT NULL AND h."usa_longitude" IS NOT NULL
    AND h."usa_latitude" BETWEEN -90 AND 90
    AND h."usa_longitude" BETWEEN -180 AND 180
GROUP BY z."zip_code"
ORDER BY "number_of_occurrences" DESC NULLS LAST;