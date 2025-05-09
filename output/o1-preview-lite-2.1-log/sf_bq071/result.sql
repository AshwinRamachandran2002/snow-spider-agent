SELECT z."zip_code", COUNT(*) AS "number_of_occurrences"
FROM "NOAA_DATA_PLUS"."GEO_US_BOUNDARIES"."ZIP_CODES" z
JOIN "NOAA_DATA_PLUS"."NOAA_HURRICANES"."HURRICANES" h
  ON ST_CONTAINS(TO_GEOGRAPHY(z."zip_code_geom"), ST_POINT(h."longitude", h."latitude"))
WHERE h."name" IS NOT NULL
  AND h."name" != 'NOT_NAMED'
  AND h."longitude" BETWEEN -180 AND 180
  AND h."latitude" BETWEEN -90 AND 90
GROUP BY z."zip_code"
ORDER BY "number_of_occurrences" DESC NULLS LAST;