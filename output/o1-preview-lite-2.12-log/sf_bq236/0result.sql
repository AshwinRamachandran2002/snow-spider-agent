SELECT "z"."zip_code", COUNT(*) AS "num_hail_events"
FROM "NOAA_DATA_PLUS"."NOAA_HISTORIC_SEVERE_STORMS"."HAIL_REPORTS" AS "h"
JOIN "NOAA_DATA_PLUS"."GEO_US_BOUNDARIES"."ZIP_CODES" AS "z"
  ON ST_CONTAINS(
      ST_GEOGRAPHYFROMWKB("z"."zip_code_geom"), 
      ST_POINT(ROUND("h"."longitude", 4), ROUND("h"."latitude", 4))
    )
WHERE TO_TIMESTAMP("h"."timestamp" / 1e6) >= DATEADD(year, -10, CURRENT_TIMESTAMP())
  AND "h"."latitude" IS NOT NULL
  AND "h"."longitude" IS NOT NULL
GROUP BY "z"."zip_code"
ORDER BY "num_hail_events" DESC NULLS LAST
LIMIT 5;