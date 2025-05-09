SELECT
   z."zip_code",
   COUNT(*) AS "num_hail_events"
FROM
   "NOAA_DATA_PLUS"."GEO_US_BOUNDARIES"."ZIP_CODES" z,
   "NOAA_DATA_PLUS"."NOAA_HISTORIC_SEVERE_STORMS"."HAIL_REPORTS" h
WHERE
   ST_WITHIN(
       ST_GEOGFROMWKB(h."report_point"),
       ST_GEOGFROMWKB(z."zip_code_geom")
   )
   AND TO_TIMESTAMP(h."timestamp" / 1000000) >= DATEADD(year, -10, CURRENT_DATE())
GROUP BY
   z."zip_code"
ORDER BY
   "num_hail_events" DESC NULLS LAST
LIMIT 5;