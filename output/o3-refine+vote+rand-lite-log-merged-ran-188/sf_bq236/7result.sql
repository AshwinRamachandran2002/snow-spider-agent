WITH hail_events AS (

    /* ---------------- 2015 ---------------- */
    SELECT CAST("event_latitude"  AS FLOAT) AS "lat",
           CAST("event_longitude" AS FLOAT) AS "lon"
    FROM   "NOAA_DATA_PLUS"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2015"
    WHERE  "event_type" ILIKE '%hail%'

    UNION ALL
    /* ---------------- 2016 ---------------- */
    SELECT CAST("event_latitude"  AS FLOAT),
           CAST("event_longitude" AS FLOAT)
    FROM   "NOAA_DATA_PLUS"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2016"
    WHERE  "event_type" ILIKE '%hail%'

    UNION ALL
    /* ---------------- 2017 ---------------- */
    SELECT CAST("event_latitude"  AS FLOAT),
           CAST("event_longitude" AS FLOAT)
    FROM   "NOAA_DATA_PLUS"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2017"
    WHERE  "event_type" ILIKE '%hail%'

    UNION ALL
    /* ---------------- 2018 ---------------- */
    SELECT CAST("event_latitude"  AS FLOAT),
           CAST("event_longitude" AS FLOAT)
    FROM   "NOAA_DATA_PLUS"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2018"
    WHERE  "event_type" ILIKE '%hail%'

    UNION ALL
    /* ---------------- 2019 ---------------- */
    SELECT CAST("event_latitude"  AS FLOAT),
           CAST("event_longitude" AS FLOAT)
    FROM   "NOAA_DATA_PLUS"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2019"
    WHERE  "event_type" ILIKE '%hail%'

    UNION ALL
    /* ---------------- 2020 ---------------- */
    SELECT CAST("event_latitude"  AS FLOAT),
           CAST("event_longitude" AS FLOAT)
    FROM   "NOAA_DATA_PLUS"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2020"
    WHERE  "event_type" ILIKE '%hail%'

    UNION ALL
    /* ---------------- 2021 ---------------- */
    SELECT CAST("event_latitude"  AS FLOAT),
           CAST("event_longitude" AS FLOAT)
    FROM   "NOAA_DATA_PLUS"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2021"
    WHERE  "event_type" ILIKE '%hail%'

    UNION ALL
    /* ---------------- 2022 ---------------- */
    SELECT CAST("event_latitude"  AS FLOAT),
           CAST("event_longitude" AS FLOAT)
    FROM   "NOAA_DATA_PLUS"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2022"
    WHERE  "event_type" ILIKE '%hail%'

    UNION ALL
    /* ---------------- 2023 ---------------- */
    SELECT CAST("event_latitude"  AS FLOAT),
           CAST("event_longitude" AS FLOAT)
    FROM   "NOAA_DATA_PLUS"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2023"
    WHERE  "event_type" ILIKE '%hail%'

    UNION ALL
    /* ---------------- 2024 ---------------- */
    SELECT CAST("event_latitude"  AS FLOAT),
           CAST("event_longitude" AS FLOAT)
    FROM   "NOAA_DATA_PLUS"."NOAA_HISTORIC_SEVERE_STORMS"."STORMS_2024"
    WHERE  "event_type" ILIKE '%hail%'

)

SELECT
       z."zip_code",
       COUNT(*) AS "hail_event_count_last_10yrs"
FROM   hail_events AS h
JOIN   "NOAA_DATA_PLUS"."GEO_US_BOUNDARIES"."ZIP_CODES" AS z
       ON ST_WITHIN(
              ST_MAKEPOINT(h."lon", h."lat"),     -- GEOGRAPHY point of hail event
              TO_GEOGRAPHY(z."zip_code_geom")     -- GEOGRAPHY polygon of ZIP code
          )
GROUP  BY z."zip_code"
ORDER  BY "hail_event_count_last_10yrs" DESC NULLS LAST
LIMIT  5;