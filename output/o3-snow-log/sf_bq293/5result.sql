/* -----------------------------------------------------------
   NYC yellow-cab pickups on 1-Jan-2015 – hourly “zip-like” stats
   (No ZIP-boundary table is available, so a surrogate “ZIP code”
    is built from a 0.01-degree lat/long grid:  lat*100 || |lon|*100)
   ----------------------------------------------------------- */
WITH
/* 1) key epoch-µs cut-offs */
PARAMS AS (
    SELECT
        1420070400000000::NUMBER AS JAN1_START_MICRO,               -- 2015-01-01 00:00:00 UTC
        1420156799000000::NUMBER AS JAN1_END_MICRO,                 -- 2015-01-01 23:59:59.9
        (1420070400000000 - 504*3600000000)::NUMBER AS WINDOW_START_MICRO  -- 21-day (504 h) look-back
),
/* 2) every hourly bucket from WINDOW_START … JAN1_END (528 rows) */
HOURS AS (
    SELECT
        (FLOOR(WINDOW_START_MICRO / 3600000000) + SEQ4()) AS HOUR_BUCKET
    FROM PARAMS,
         TABLE(GENERATOR(ROWCOUNT => 528))                            -- 504 look-back + 24 Jan-1 hrs
),
/* 3) trips inside the 21-day window with coarse “ZIP” surrogate */
TRIPS_WIN AS (
    SELECT
        FLOOR(t."pickup_datetime" / 3600000000) AS HOUR_BUCKET,
        /* 4-digit lat grid + 4-digit |lon| grid  → pseudo-ZIP */
        LPAD(TO_VARCHAR(FLOOR(t."pickup_latitude"  * 100)), 4, '0') ||
        LPAD(TO_VARCHAR(FLOOR(ABS(t."pickup_longitude") * 100)), 4, '0') AS ZIP_CODE
    FROM "NEW_YORK_GEO"."NEW_YORK"."TLC_YELLOW_TRIPS_2015" t
    JOIN PARAMS p
      ON t."pickup_datetime" BETWEEN p.WINDOW_START_MICRO AND p.JAN1_END_MICRO
    WHERE t."pickup_latitude"  BETWEEN 40.4 AND 41.0
      AND t."pickup_longitude" BETWEEN -74.3 AND -73.4
),
/* 4) distinct surrogate ZIPs observed in the window */
ZIPCODES AS (SELECT DISTINCT ZIP_CODE FROM TRIPS_WIN),
/* 5) zero-filled hour-by-ZIP grid */
HOURLY_ZIP AS (
    SELECT
        h.HOUR_BUCKET,
        z.ZIP_CODE,
        COALESCE(COUNT(t.ZIP_CODE), 0) AS TRIPS
    FROM HOURS h
    CROSS JOIN ZIPCODES z
    LEFT JOIN TRIPS_WIN t
           ON t.HOUR_BUCKET = h.HOUR_BUCKET
          AND t.ZIP_CODE    = z.ZIP_CODE
    GROUP BY h.HOUR_BUCKET, z.ZIP_CODE
),
/* 6) lagged metrics & rolling statistics (exclude current hour) */
METRICS AS (
    SELECT
        hz.ZIP_CODE,
        hz.HOUR_BUCKET,
        hz.TRIPS,
        LAG(hz.TRIPS,   1) OVER (PARTITION BY hz.ZIP_CODE ORDER BY hz.HOUR_BUCKET) AS TRIPS_PREV_1H,
        LAG(hz.TRIPS,  24) OVER (PARTITION BY hz.ZIP_CODE ORDER BY hz.HOUR_BUCKET) AS TRIPS_PREV_24H,
        LAG(hz.TRIPS, 168) OVER (PARTITION BY hz.ZIP_CODE ORDER BY hz.HOUR_BUCKET) AS TRIPS_PREV_168H,
        LAG(hz.TRIPS, 336) OVER (PARTITION BY hz.ZIP_CODE ORDER BY hz.HOUR_BUCKET) AS TRIPS_PREV_336H,
        AVG(hz.TRIPS)       OVER (PARTITION BY hz.ZIP_CODE ORDER BY hz.HOUR_BUCKET
                                   ROWS BETWEEN 336 PRECEDING AND 1 PRECEDING)     AS MA_14D,
        STDDEV_POP(hz.TRIPS) OVER (PARTITION BY hz.ZIP_CODE ORDER BY hz.HOUR_BUCKET
                                   ROWS BETWEEN 336 PRECEDING AND 1 PRECEDING)     AS STDDEV_14D,
        AVG(hz.TRIPS)       OVER (PARTITION BY hz.ZIP_CODE ORDER BY hz.HOUR_BUCKET
                                   ROWS BETWEEN 504 PRECEDING AND 1 PRECEDING)     AS MA_21D,
        STDDEV_POP(hz.TRIPS) OVER (PARTITION BY hz.ZIP_CODE ORDER BY hz.HOUR_BUCKET
                                   ROWS BETWEEN 504 PRECEDING AND 1 PRECEDING)     AS STDDEV_21D
    FROM HOURLY_ZIP hz
),
/* 7) retain only the 24 hourly buckets of 1-Jan-2015 */
JAN1_METRICS AS (
    SELECT *
    FROM METRICS m, PARAMS p
    WHERE m.HOUR_BUCKET BETWEEN FLOOR(p.JAN1_START_MICRO / 3600000000)
                           AND FLOOR(p.JAN1_END_MICRO   / 3600000000)
)
/* 8) top-5 surrogate-ZIP/hour combinations by trip volume */
SELECT
    ZIP_CODE,
    HOUR_BUCKET,
    TRIPS,
    TRIPS_PREV_1H,
    TRIPS_PREV_24H,
    TRIPS_PREV_168H,
    TRIPS_PREV_336H,
    MA_14D,
    STDDEV_14D,
    MA_21D,
    STDDEV_21D
FROM JAN1_METRICS
ORDER BY TRIPS DESC NULLS LAST
LIMIT 5;