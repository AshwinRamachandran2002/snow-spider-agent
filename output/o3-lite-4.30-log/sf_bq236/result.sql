WITH hail_events AS (               -- hail points from the most‑recent 10‑year window
    SELECT
        "event_id",
        ST_MAKEPOINT("event_longitude", "event_latitude") AS "event_geo"
    FROM (
        SELECT * FROM "NOAA_DATA_PLUS"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2014"
        UNION ALL
        SELECT * FROM "NOAA_DATA_PLUS"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2015"
        UNION ALL
        SELECT * FROM "NOAA_DATA_PLUS"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2016"
        UNION ALL
        SELECT * FROM "NOAA_DATA_PLUS"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2017"
        UNION ALL
        SELECT * FROM "NOAA_DATA_PLUS"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2018"
        UNION ALL
        SELECT * FROM "NOAA_DATA_PLUS"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2019"
        UNION ALL
        SELECT * FROM "NOAA_DATA_PLUS"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2020"
        UNION ALL
        SELECT * FROM "NOAA_DATA_PLUS"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2021"
        UNION ALL
        SELECT * FROM "NOAA_DATA_PLUS"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2022"
        UNION ALL
        SELECT * FROM "NOAA_DATA_PLUS"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2023"
        UNION ALL
        SELECT * FROM "NOAA_DATA_PLUS"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2024"
    )
    WHERE "event_type" = 'hail'
      AND "event_latitude"  IS NOT NULL
      AND "event_longitude" IS NOT NULL
),
hail_by_zip AS (                     -- spatially join hail points to ZIP polygons
    SELECT
        MIN(z."city") AS "area_name",                -- representative place name
        z."zip_code",
        COUNT(*)      AS "hail_event_count"
    FROM hail_events h
    JOIN "NOAA_DATA_PLUS"."GEO_US_BOUNDARIES"."ZIP_CODES" z
      ON ST_WITHIN(h."event_geo", ST_GEOGFROMWKB(z."zip_code_geom"))
    GROUP BY z."zip_code"
)
SELECT
    "area_name",
    "zip_code",
    "hail_event_count"
FROM hail_by_zip
ORDER BY "hail_event_count" DESC NULLS LAST, "zip_code"
LIMIT 5;