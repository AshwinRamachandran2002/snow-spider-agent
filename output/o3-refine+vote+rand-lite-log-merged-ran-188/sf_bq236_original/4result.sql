WITH hail_events AS (
    SELECT
        TO_TIMESTAMP("timestamp" / 1000000)          AS event_ts,
        ST_MAKEPOINT("longitude", "latitude")        AS hail_geom
    FROM NOAA_DATA_PLUS.NOAA_PRELIMINARY_SEVERE_STORMS.HAIL_REPORTS
    WHERE "longitude" IS NOT NULL
      AND "latitude"  IS NOT NULL
      AND TO_TIMESTAMP("timestamp" / 1000000) >= DATEADD(year, -10, CURRENT_TIMESTAMP())
),
us_zip_geoms AS (
    SELECT
        "zip_code",
        TO_GEOGRAPHY("zip_code_geom") AS zip_geom
    FROM NOAA_DATA_PLUS.GEO_US_BOUNDARIES.ZIP_CODES
    WHERE "zip_code_geom" IS NOT NULL
)
SELECT
    z."zip_code",
    COUNT(*) AS hail_event_count
FROM hail_events h
JOIN us_zip_geoms z
  ON ST_WITHIN(h.hail_geom, z.zip_geom)
GROUP BY z."zip_code"
ORDER BY hail_event_count DESC NULLS LAST,
         z."zip_code"
LIMIT 5;