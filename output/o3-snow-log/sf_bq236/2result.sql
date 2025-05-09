WITH hail_events AS (

    /* ----------  collect all hail-storm points (2014-2023)  ---------- */
    SELECT TO_GEOGRAPHY("event_point") AS geom
    FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2014
    WHERE "event_type" ILIKE '%hail%' AND "event_point" IS NOT NULL

    UNION ALL
    SELECT TO_GEOGRAPHY("event_point") 
    FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2015
    WHERE "event_type" ILIKE '%hail%' AND "event_point" IS NOT NULL

    UNION ALL
    SELECT TO_GEOGRAPHY("event_point")
    FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2016
    WHERE "event_type" ILIKE '%hail%' AND "event_point" IS NOT NULL

    UNION ALL
    SELECT TO_GEOGRAPHY("event_point")
    FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2017
    WHERE "event_type" ILIKE '%hail%' AND "event_point" IS NOT NULL

    UNION ALL
    SELECT TO_GEOGRAPHY("event_point")
    FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2018
    WHERE "event_type" ILIKE '%hail%' AND "event_point" IS NOT NULL

    UNION ALL
    SELECT TO_GEOGRAPHY("event_point")
    FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2019
    WHERE "event_type" ILIKE '%hail%' AND "event_point" IS NOT NULL

    UNION ALL
    SELECT TO_GEOGRAPHY("event_point")
    FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2020
    WHERE "event_type" ILIKE '%hail%' AND "event_point" IS NOT NULL

    UNION ALL
    SELECT TO_GEOGRAPHY("event_point")
    FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2021
    WHERE "event_type" ILIKE '%hail%' AND "event_point" IS NOT NULL

    UNION ALL
    SELECT TO_GEOGRAPHY("event_point")
    FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2022
    WHERE "event_type" ILIKE '%hail%' AND "event_point" IS NOT NULL

    UNION ALL
    SELECT TO_GEOGRAPHY("event_point")
    FROM NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS.STORMS_2023
    WHERE "event_type" ILIKE '%hail%' AND "event_point" IS NOT NULL
)

SELECT 
       z."zip_code",
       COUNT(*) AS hail_event_cnt
FROM   hail_events h
JOIN   NOAA_DATA_PLUS.GEO_US_BOUNDARIES.ZIP_CODES z
       ON ST_CONTAINS( TO_GEOGRAPHY(z."zip_code_geom"), h.geom )
GROUP  BY z."zip_code"
ORDER  BY hail_event_cnt DESC NULLS LAST
LIMIT 5;