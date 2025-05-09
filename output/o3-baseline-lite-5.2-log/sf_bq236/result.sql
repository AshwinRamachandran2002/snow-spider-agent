/*  Top 5 U.S. ZIP codes with the greatest number of hail‑storm events
    recorded during the last 10 calendar years (2014‑‑2023), based on the
    historic “STORMS_20xx” tables (event_type = 'hail').
*/
WITH hail_events AS (

    /* -------- 2014 -------- */
    SELECT TO_GEOGRAPHY('POINT(' || CAST("event_longitude" AS STRING)
                                  || ' ' || CAST("event_latitude"  AS STRING) || ')') AS "point"
    FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2014
    WHERE "event_type" = 'hail'
      AND "event_longitude" IS NOT NULL
      AND "event_latitude"  IS NOT NULL

    UNION ALL
    /* -------- 2015 -------- */
    SELECT TO_GEOGRAPHY('POINT(' || CAST("event_longitude" AS STRING)
                                  || ' ' || CAST("event_latitude"  AS STRING) || ')')
    FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2015
    WHERE "event_type" = 'hail'
      AND "event_longitude" IS NOT NULL
      AND "event_latitude"  IS NOT NULL

    UNION ALL
    /* -------- 2016 -------- */
    SELECT TO_GEOGRAPHY('POINT(' || CAST("event_longitude" AS STRING)
                                  || ' ' || CAST("event_latitude"  AS STRING) || ')')
    FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2016
    WHERE "event_type" = 'hail'
      AND "event_longitude" IS NOT NULL
      AND "event_latitude"  IS NOT NULL

    UNION ALL
    /* -------- 2017 -------- */
    SELECT TO_GEOGRAPHY('POINT(' || CAST("event_longitude" AS STRING)
                                  || ' ' || CAST("event_latitude"  AS STRING) || ')')
    FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2017
    WHERE "event_type" = 'hail'
      AND "event_longitude" IS NOT NULL
      AND "event_latitude"  IS NOT NULL

    UNION ALL
    /* -------- 2018 -------- */
    SELECT TO_GEOGRAPHY('POINT(' || CAST("event_longitude" AS STRING)
                                  || ' ' || CAST("event_latitude"  AS STRING) || ')')
    FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2018
    WHERE "event_type" = 'hail'
      AND "event_longitude" IS NOT NULL
      AND "event_latitude"  IS NOT NULL

    UNION ALL
    /* -------- 2019 -------- */
    SELECT TO_GEOGRAPHY('POINT(' || CAST("event_longitude" AS STRING)
                                  || ' ' || CAST("event_latitude"  AS STRING) || ')')
    FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2019
    WHERE "event_type" = 'hail'
      AND "event_longitude" IS NOT NULL
      AND "event_latitude"  IS NOT NULL

    UNION ALL
    /* -------- 2020 -------- */
    SELECT TO_GEOGRAPHY('POINT(' || CAST("event_longitude" AS STRING)
                                  || ' ' || CAST("event_latitude"  AS STRING) || ')')
    FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2020
    WHERE "event_type" = 'hail'
      AND "event_longitude" IS NOT NULL
      AND "event_latitude"  IS NOT NULL

    UNION ALL
    /* -------- 2021 -------- */
    SELECT TO_GEOGRAPHY('POINT(' || CAST("event_longitude" AS STRING)
                                  || ' ' || CAST("event_latitude"  AS STRING) || ')')
    FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2021
    WHERE "event_type" = 'hail'
      AND "event_longitude" IS NOT NULL
      AND "event_latitude"  IS NOT NULL

    UNION ALL
    /* -------- 2022 -------- */
    SELECT TO_GEOGRAPHY('POINT(' || CAST("event_longitude" AS STRING)
                                  || ' ' || CAST("event_latitude"  AS STRING) || ')')
    FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2022
    WHERE "event_type" = 'hail'
      AND "event_longitude" IS NOT NULL
      AND "event_latitude"  IS NOT NULL

    UNION ALL
    /* -------- 2023 -------- */
    SELECT TO_GEOGRAPHY('POINT(' || CAST("event_longitude" AS STRING)
                                  || ' ' || CAST("event_latitude"  AS STRING) || ')')
    FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2023
    WHERE "event_type" = 'hail'
      AND "event_longitude" IS NOT NULL
      AND "event_latitude"  IS NOT NULL

    UNION ALL
    /* -------- 2024 -------- */
    SELECT TO_GEOGRAPHY('POINT(' || CAST("event_longitude" AS STRING)
                                  || ' ' || CAST("event_latitude"  AS STRING) || ')')
    FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2024
    WHERE "event_type" = 'hail'
      AND "event_longitude" IS NOT NULL
      AND "event_latitude"  IS NOT NULL
),

events_by_zip AS (
    SELECT
        z."zip_code",
        COUNT(*) AS hail_event_count
    FROM hail_events h
    JOIN NOAA_DATA_PLUS.GEO_US_BOUNDARIES.ZIP_CODES z
      ON ST_WITHIN(
             h."point",
             TO_GEOGRAPHY(z."zip_code_geom")
         )
    GROUP BY z."zip_code"
)

SELECT
    "zip_code",
    hail_event_count
FROM events_by_zip
ORDER BY hail_event_count DESC NULLS LAST, "zip_code"
LIMIT 5;