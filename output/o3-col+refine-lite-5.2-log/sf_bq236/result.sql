/* Top‑5 U.S. ZIP codes with the greatest number of hail‑storm events
   recorded in the last 10 years (2014‑2023)                           */
WITH hail_events AS (

    /* ----------------------------- 2014 ---------------------------- */
    SELECT  "event_latitude"  AS lat ,
            "event_longitude" AS lon
    FROM    NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2014"
    WHERE   "event_type" ILIKE '%hail%'

    UNION ALL
    /* ----------------------------- 2015 ---------------------------- */
    SELECT  "event_latitude", "event_longitude"
    FROM    NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2015"
    WHERE   "event_type" ILIKE '%hail%'

    UNION ALL
    /* ----------------------------- 2016 ---------------------------- */
    SELECT  "event_latitude", "event_longitude"
    FROM    NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2016"
    WHERE   "event_type" ILIKE '%hail%'

    UNION ALL
    /* ----------------------------- 2017 ---------------------------- */
    SELECT  "event_latitude", "event_longitude"
    FROM    NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2017"
    WHERE   "event_type" ILIKE '%hail%'

    UNION ALL
    /* ----------------------------- 2018 ---------------------------- */
    SELECT  "event_latitude", "event_longitude"
    FROM    NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2018"
    WHERE   "event_type" ILIKE '%hail%'

    UNION ALL
    /* ----------------------------- 2019 ---------------------------- */
    SELECT  "event_latitude", "event_longitude"
    FROM    NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2019"
    WHERE   "event_type" ILIKE '%hail%'

    UNION ALL
    /* ----------------------------- 2020 ---------------------------- */
    SELECT  "event_latitude", "event_longitude"
    FROM    NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2020"
    WHERE   "event_type" ILIKE '%hail%'

    UNION ALL
    /* ----------------------------- 2021 ---------------------------- */
    SELECT  "event_latitude", "event_longitude"
    FROM    NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2021"
    WHERE   "event_type" ILIKE '%hail%'

    UNION ALL
    /* ----------------------------- 2022 ---------------------------- */
    SELECT  "event_latitude", "event_longitude"
    FROM    NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2022"
    WHERE   "event_type" ILIKE '%hail%'

    UNION ALL
    /* ----------------------------- 2023 ---------------------------- */
    SELECT  "event_latitude", "event_longitude"
    FROM    NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2023"
    WHERE   "event_type" ILIKE '%hail%'

), hail_points AS (
    /* keep only rows with valid coordinates */
    SELECT  lat , lon
    FROM    hail_events
    WHERE   lat IS NOT NULL
      AND   lon IS NOT NULL
)

SELECT
       z."zip_code",
       COUNT(*) AS "hail_event_count_last_10yrs"
FROM   hail_points h
JOIN   NOAA_DATA_PLUS.GEO_US_BOUNDARIES."ZIP_CODES" z
       ON ST_WITHIN(
              ST_POINT( h.lon , h.lat ),
              TO_GEOGRAPHY( z."zip_code_geom" )
          )
GROUP  BY z."zip_code"
ORDER  BY "hail_event_count_last_10yrs" DESC NULLS LAST,
          z."zip_code"
LIMIT  5;