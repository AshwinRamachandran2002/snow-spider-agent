SELECT z."zip_code", COUNT(*) AS "number_of_occurrences"
FROM "NOAA_DATA_PLUS"."NOAA_HURRICANES"."HURRICANES" h
JOIN "NOAA_DATA_PLUS"."GEO_US_BOUNDARIES"."ZIP_CODES" z
  ON ST_WITHIN(
       ST_MAKEPOINT(h."longitude", h."latitude"),
       ST_GEOGFROMWKB(z."zip_code_geom")
     )
WHERE h."name" IS NOT NULL
  AND h."latitude" IS NOT NULL
  AND h."longitude" IS NOT NULL
  AND h."latitude" BETWEEN -90 AND 90
  AND h."longitude" BETWEEN -180 AND 180
GROUP BY z."zip_code"
ORDER BY "number_of_occurrences" DESC NULLS LAST;