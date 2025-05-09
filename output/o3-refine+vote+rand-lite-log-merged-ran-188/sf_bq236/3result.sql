/*  Top-5 U.S. ZIP codes that experienced the greatest number of hail-storm
    events during the last 10 years (2014 – 2024)                       */

WITH all_storms AS (           -- 1.  Stack the last-10-year Storm-Data tables
    SELECT  "event_latitude",
            "event_longitude",
            "event_type"
    FROM   "NOAA_DATA_PLUS"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2014"
    UNION ALL
    SELECT  "event_latitude","event_longitude","event_type"
    FROM   "NOAA_DATA_PLUS"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2015"
    UNION ALL
    SELECT  "event_latitude","event_longitude","event_type"
    FROM   "NOAA_DATA_PLUS"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2016"
    UNION ALL
    SELECT  "event_latitude","event_longitude","event_type"
    FROM   "NOAA_DATA_PLUS"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2017"
    UNION ALL
    SELECT  "event_latitude","event_longitude","event_type"
    FROM   "NOAA_DATA_PLUS"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2018"
    UNION ALL
    SELECT  "event_latitude","event_longitude","event_type"
    FROM   "NOAA_DATA_PLUS"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2019"
    UNION ALL
    SELECT  "event_latitude","event_longitude","event_type"
    FROM   "NOAA_DATA_PLUS"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2020"
    UNION ALL
    SELECT  "event_latitude","event_longitude","event_type"
    FROM   "NOAA_DATA_PLUS"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2021"
    UNION ALL
    SELECT  "event_latitude","event_longitude","event_type"
    FROM   "NOAA_DATA_PLUS"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2022"
    UNION ALL
    SELECT  "event_latitude","event_longitude","event_type"
    FROM   "NOAA_DATA_PLUS"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2023"
    UNION ALL
    SELECT  "event_latitude","event_longitude","event_type"
    FROM   "NOAA_DATA_PLUS"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2024"
), hail_events AS (             -- 2.  Keep only hail-type events
    SELECT  "event_latitude",
            "event_longitude"
    FROM    all_storms
    WHERE   "event_type" ILIKE '%hail%'
)
SELECT  z."zip_code",
        COUNT(*) AS "hail_event_count"
FROM    hail_events                h
JOIN    "NOAA_DATA_PLUS"."GEO_US_BOUNDARIES"."ZIP_CODES"  z
          ON ST_WITHIN(
                 ST_MAKEPOINT(h."event_longitude", h."event_latitude"),
                 TO_GEOGRAPHY(z."zip_code_geom")
             )
GROUP BY z."zip_code"
ORDER BY "hail_event_count" DESC NULLS LAST
LIMIT 5;