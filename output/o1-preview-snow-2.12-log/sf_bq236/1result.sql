SELECT z."zip_code", COUNT(*) AS "num_hail_events"
FROM
  "NOAA_DATA_PLUS"."NOAA_HISTORIC_SEVERE_STORMS"."HAIL_REPORTS" h,
  "NOAA_DATA_PLUS"."GEO_US_BOUNDARIES"."ZIP_CODES" z
WHERE
  h."timestamp" >= DATE_PART(epoch_second, DATEADD(year, -10, CURRENT_TIMESTAMP()))
  AND ST_WITHIN(
    ST_MAKEPOINT(h."longitude", h."latitude"),
    ST_GEOGFROMWKB(z."zip_code_geom")
  )
GROUP BY z."zip_code"
ORDER BY "num_hail_events" DESC NULLS LAST, z."zip_code" ASC
LIMIT 5;