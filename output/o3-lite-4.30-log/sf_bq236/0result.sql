WITH all_storms AS (
    SELECT "event_point"
    FROM (
        SELECT "event_point", "event_type" FROM "NOAA_DATA_PLUS"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2014"
        UNION ALL
        SELECT "event_point", "event_type" FROM "NOAA_DATA_PLUS"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2015"
        UNION ALL
        SELECT "event_point", "event_type" FROM "NOAA_DATA_PLUS"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2016"
        UNION ALL
        SELECT "event_point", "event_type" FROM "NOAA_DATA_PLUS"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2017"
        UNION ALL
        SELECT "event_point", "event_type" FROM "NOAA_DATA_PLUS"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2018"
        UNION ALL
        SELECT "event_point", "event_type" FROM "NOAA_DATA_PLUS"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2019"
        UNION ALL
        SELECT "event_point", "event_type" FROM "NOAA_DATA_PLUS"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2020"
        UNION ALL
        SELECT "event_point", "event_type" FROM "NOAA_DATA_PLUS"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2021"
        UNION ALL
        SELECT "event_point", "event_type" FROM "NOAA_DATA_PLUS"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2022"
        UNION ALL
        SELECT "event_point", "event_type" FROM "NOAA_DATA_PLUS"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2023"
        UNION ALL
        SELECT "event_point", "event_type" FROM "NOAA_DATA_PLUS"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2024"
    )
    WHERE LOWER("event_type") = 'hail'
      AND "event_point" IS NOT NULL
)
SELECT
    "city" || ', ' || "state_code" AS area_name,
    "zip_code",
    COUNT(*)                       AS hail_event_count
FROM all_storms h
JOIN "NOAA_DATA_PLUS"."GEO_US_BOUNDARIES"."ZIP_CODES" z
  ON ST_WITHIN(
        TO_GEOGRAPHY(h."event_point"),
        TO_GEOGRAPHY(z."zip_code_geom")
     )
GROUP BY "city", "state_code", "zip_code"
ORDER BY hail_event_count DESC NULLS LAST, "zip_code"
LIMIT 5;