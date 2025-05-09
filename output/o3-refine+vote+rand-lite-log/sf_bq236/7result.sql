/*  Top‑5 U.S. ZIP codes with the greatest number of hail‑storm events
    during the most recent 10‑year period (2014‑2023), using the annual
    NOAA “STORMS_YYYY” tables rather than any “HAIL_REPORTS” tables.   */

WITH hail_events AS (

    /* --- 2014 ------------------------------------------------------- */
    SELECT  "event_latitude"  AS lat,
            "event_longitude" AS lon
    FROM    NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2014"
    WHERE   LOWER("event_type") = 'hail'
      AND   "event_latitude"  IS NOT NULL
      AND   "event_longitude" IS NOT NULL

    UNION ALL
    /* --- 2015 ------------------------------------------------------- */
    SELECT  "event_latitude", "event_longitude"
    FROM    NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2015"
    WHERE   LOWER("event_type") = 'hail'
      AND   "event_latitude"  IS NOT NULL
      AND   "event_longitude" IS NOT NULL

    UNION ALL
    /* --- 2016 ------------------------------------------------------- */
    SELECT  "event_latitude", "event_longitude"
    FROM    NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2016"
    WHERE   LOWER("event_type") = 'hail'
      AND   "event_latitude"  IS NOT NULL
      AND   "event_longitude" IS NOT NULL

    UNION ALL
    /* --- 2017 ------------------------------------------------------- */
    SELECT  "event_latitude", "event_longitude"
    FROM    NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2017"
    WHERE   LOWER("event_type") = 'hail'
      AND   "event_latitude"  IS NOT NULL
      AND   "event_longitude" IS NOT NULL

    UNION ALL
    /* --- 2018 ------------------------------------------------------- */
    SELECT  "event_latitude", "event_longitude"
    FROM    NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2018"
    WHERE   LOWER("event_type") = 'hail'
      AND   "event_latitude"  IS NOT NULL
      AND   "event_longitude" IS NOT NULL

    UNION ALL
    /* --- 2019 ------------------------------------------------------- */
    SELECT  "event_latitude", "event_longitude"
    FROM    NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2019"
    WHERE   LOWER("event_type") = 'hail'
      AND   "event_latitude"  IS NOT NULL
      AND   "event_longitude" IS NOT NULL

    UNION ALL
    /* --- 2020 ------------------------------------------------------- */
    SELECT  "event_latitude", "event_longitude"
    FROM    NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2020"
    WHERE   LOWER("event_type") = 'hail'
      AND   "event_latitude"  IS NOT NULL
      AND   "event_longitude" IS NOT NULL

    UNION ALL
    /* --- 2021 ------------------------------------------------------- */
    SELECT  "event_latitude", "event_longitude"
    FROM    NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2021"
    WHERE   LOWER("event_type") = 'hail'
      AND   "event_latitude"  IS NOT NULL
      AND   "event_longitude" IS NOT NULL

    UNION ALL
    /* --- 2022 ------------------------------------------------------- */
    SELECT  "event_latitude", "event_longitude"
    FROM    NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2022"
    WHERE   LOWER("event_type") = 'hail'
      AND   "event_latitude"  IS NOT NULL
      AND   "event_longitude" IS NOT NULL

    UNION ALL
    /* --- 2023 ------------------------------------------------------- */
    SELECT  "event_latitude", "event_longitude"
    FROM    NOAA_DATA_PLUS.NOAA_HISTORIC_SEVERE_STORMS."STORMS_2023"
    WHERE   LOWER("event_type") = 'hail'
      AND   "event_latitude"  IS NOT NULL
      AND   "event_longitude" IS NOT NULL
),

/* Convert each hail record to a GEOGRAPHY point --------------------- */
hail_points AS (
    SELECT ST_MAKEPOINT(lon, lat) AS hail_geom
    FROM   hail_events
),

/* Match hail points to ZIP‑code polygons --------------------------- */
hail_by_zip AS (
    SELECT  z."zip_code"                       AS zip,
            COUNT(*)                           AS hail_cnt
    FROM    hail_points   p
    JOIN    NOAA_DATA_PLUS.GEO_US_BOUNDARIES."ZIP_CODES" z
           ON ST_WITHIN( p.hail_geom,
                         TO_GEOGRAPHY( z."zip_code_geom" ) )
    GROUP BY z."zip_code"
)

SELECT  zip,
        hail_cnt
FROM    hail_by_zip
ORDER BY hail_cnt DESC NULLS LAST,
         zip
FETCH FIRST 5 ROWS ONLY;