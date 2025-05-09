WITH hail_events AS (
    SELECT
        "event_id",
        COALESCE(
            ST_GEOGFROMWKB("event_point"),
            CASE
                WHEN "event_longitude" IS NOT NULL 
                     AND "event_latitude"  IS NOT NULL
                THEN ST_POINT("event_longitude", "event_latitude")
            END
        ) AS "hail_geog"
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
    ) t
    WHERE LOWER("event_type") = 'hail'
),
zip_polygons AS (
    SELECT
        "zip_code",
        "city" AS "area_name",
        ST_GEOGFROMWKB("zip_code_geom") AS "zip_geog"
    FROM "NOAA_DATA_PLUS"."GEO_US_BOUNDARIES"."ZIP_CODES"
)
SELECT
    z."area_name",
    z."zip_code",
    COUNT(*) AS "hail_event_count"
FROM hail_events h
JOIN zip_polygons z
      ON h."hail_geog" IS NOT NULL
     AND ST_WITHIN(h."hail_geog", z."zip_geog")
GROUP BY z."area_name", z."zip_code"
ORDER BY "hail_event_count" DESC NULLS LAST, z."zip_code"
LIMIT 5;