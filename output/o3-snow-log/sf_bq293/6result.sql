/* ---------------------------------------------------------------
   Hour-by-hour New-Year-Day (01-Jan-2015) yellow-cab pickups
   – including zero-trip hours – together with lagged counts
   and moving-window statistics.
   NOTE:  A ZIP-code-boundary table is not available in the
   current environment, so the analysis is carried out for the
   whole city, using the literal value 'ALL' as the ZIP code.
---------------------------------------------------------------- */

WITH
/* 1)  24 hourly buckets for 1-Jan-2015 (UTC-naïve) */
hours AS (
    SELECT DATEADD(
               hour,
               seq4(),
               TO_TIMESTAMP_NTZ('2015-01-01 00:00:00')
           )                       AS "hour_start"
    FROM TABLE(GENERATOR(ROWCOUNT => 24))
),

/* 2)  Dummy “ZIP” list (single value covering all NYC) */
nyc_zips AS (
    SELECT 'ALL'::VARCHAR AS "zip_code"
),

/* 3)  Raw trips on 01-Jan-2015 with plausible coordinates          */
jan01_trips AS (
    SELECT
        TO_TIMESTAMP_NTZ(t."pickup_datetime" / 1000000) AS "pickup_ts",
        t."pickup_latitude"                             AS "lat",
        t."pickup_longitude"                            AS "lon"
    FROM  NEW_YORK_GEO.NEW_YORK.TLC_YELLOW_TRIPS_2015 t
    WHERE t."pickup_datetime" >= 1420070400000000         /* 2015-01-01 00:00:00 */
      AND t."pickup_datetime" <  1420156800000000         /* 2015-01-02 00:00:00 */
      AND t."pickup_latitude"  BETWEEN 40 AND 41          /* sanity filter       */
      AND t."pickup_longitude" BETWEEN -75 AND -72
),

/* 4)  City-wide (single “ZIP”) trip counts per hour                */
trips_zip_hour AS (
    SELECT
        'ALL'                                          AS "zip_code",
        DATE_TRUNC('hour', j."pickup_ts")              AS "hour_start",
        COUNT(*)                                       AS "trip_cnt"
    FROM   jan01_trips j
    GROUP  BY DATE_TRUNC('hour', j."pickup_ts")
),

/* 5)  Cross-product of ZIPs × 24 hours to guarantee zero rows       */
all_zip_hour AS (
    SELECT  z."zip_code",
            h."hour_start"
    FROM    nyc_zips z
    CROSS   JOIN hours   h
),

/* 6)  Merge real counts and fill gaps with 0                        */
zip_hour_series AS (
    SELECT
        a."zip_code",
        a."hour_start",
        COALESCE(t."trip_cnt", 0) AS "trip_cnt"
    FROM      all_zip_hour   a
    LEFT JOIN trips_zip_hour t
           ON t."zip_code"   = a."zip_code"
          AND t."hour_start" = a."hour_start"
),

/* 7)  Lagged counts and moving-window statistics                    */
metrics AS (
    SELECT
        zhs."zip_code",
        zhs."hour_start",
        zhs."trip_cnt",

        /* simple lags */
        LAG (zhs."trip_cnt",  1) OVER (PARTITION BY zhs."zip_code"
                                       ORDER BY     zhs."hour_start")  AS "cnt_1hr_ago",
        LAG (zhs."trip_cnt", 24) OVER (PARTITION BY zhs."zip_code"
                                       ORDER BY     zhs."hour_start")  AS "cnt_24hr_ago",
        LAG (zhs."trip_cnt",168) OVER (PARTITION BY zhs."zip_code"
                                       ORDER BY     zhs."hour_start")  AS "cnt_168hr_ago",
        LAG (zhs."trip_cnt",336) OVER (PARTITION BY zhs."zip_code"
                                       ORDER BY     zhs."hour_start")  AS "cnt_336hr_ago",

        /* 14-day (336-hour) moving stats – exclude current hour */
        AVG    (zhs."trip_cnt") OVER (PARTITION BY zhs."zip_code"
                                      ORDER BY     zhs."hour_start"
                                      ROWS BETWEEN 336 PRECEDING AND 1 PRECEDING) AS "ma_14day",
        STDDEV (zhs."trip_cnt") OVER (PARTITION BY zhs."zip_code"
                                      ORDER BY     zhs."hour_start"
                                      ROWS BETWEEN 336 PRECEDING AND 1 PRECEDING) AS "sd_14day",

        /* 21-day (504-hour) moving stats – exclude current hour */
        AVG    (zhs."trip_cnt") OVER (PARTITION BY zhs."zip_code"
                                      ORDER BY     zhs."hour_start"
                                      ROWS BETWEEN 504 PRECEDING AND 1 PRECEDING) AS "ma_21day",
        STDDEV (zhs."trip_cnt") OVER (PARTITION BY zhs."zip_code"
                                      ORDER BY     zhs."hour_start"
                                      ROWS BETWEEN 504 PRECEDING AND 1 PRECEDING) AS "sd_21day"
    FROM zip_hour_series zhs
)

/* ----------------------------------------------------------------- */
/* 8)  Show the 5 hour-rows with the highest trip counts              */
SELECT *
FROM   metrics
ORDER  BY "trip_cnt" DESC NULLS LAST
LIMIT  5;