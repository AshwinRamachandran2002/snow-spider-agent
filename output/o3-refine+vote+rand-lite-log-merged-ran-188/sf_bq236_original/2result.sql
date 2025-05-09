WITH hail_events AS (
    /* 1.  Gather hail storm reports from the last 10 years
          (micro‑seconds epoch → TIMESTAMP_LTZ)                          */
    SELECT
        TO_TIMESTAMP_LTZ("timestamp" / 1000000)          AS event_time,
        TO_GEOGRAPHY("report_point")                     AS hail_geom
    FROM NOAA_DATA_PLUS.NOAA_PRELIMINARY_SEVERE_STORMS.HAIL_REPORTS
    WHERE TO_TIMESTAMP_LTZ("timestamp" / 1000000)
          >= DATEADD(year, -10, CURRENT_TIMESTAMP())          -- past 10 years
          AND "report_point" IS NOT NULL
),

zip_shapes AS (
    /* 2.  Zip‑code polygons                                            */
    SELECT
        "zip_code"                                         AS zip,
        TO_GEOGRAPHY("zip_code_geom")                      AS zip_geom
    FROM NOAA_DATA_PLUS.GEO_US_BOUNDARIES.ZIP_CODES
)

SELECT
    z.zip                              AS "ZIP_CODE",
    COUNT(*)                           AS "HAIL_EVENT_COUNT"
FROM hail_events      h
JOIN zip_shapes       z
  ON ST_WITHIN(h.hail_geom, z.zip_geom)                    -- point ∈ ZIP
GROUP BY z.zip
ORDER BY "HAIL_EVENT_COUNT" DESC NULLS LAST, "ZIP_CODE"
LIMIT 5;