/* --------------------------------------------------------------
   Hour-by-hour NYC Yellow-taxi pickup counts for 1-Jan-2015.
   “ZIP” is approximated by the 3-decimal (≈ 110 m) lat/long cell
   because a true ZIP-boundary table is not available here.
---------------------------------------------------------------- */

WITH
/* 1)  21-day history of trips inside a coarse NYC bounding box */
raw_trips AS (
    SELECT
        TO_TIMESTAMP_NTZ("pickup_datetime" / 1000000)                     AS pickup_ts ,
        DATE_TRUNC('hour', TO_TIMESTAMP_NTZ("pickup_datetime" / 1000000)) AS pickup_hr ,
        "pickup_latitude"                                                 AS lat ,
        "pickup_longitude"                                                AS lon
    FROM "NEW_YORK_GEO"."NEW_YORK"."TLC_YELLOW_TRIPS_2015"
    WHERE "pickup_datetime" BETWEEN 1418342400000000   -- 2014-12-12 00:00 UTC
                              AND     1420156799000000  -- 2015-01-01 23:59:59 UTC
      AND "pickup_latitude"  BETWEEN 40 AND 41
      AND "pickup_longitude" BETWEEN -75 AND -72
),

/* 2)  Map every trip to a 3-decimal “cell”; treat that cell as “zip” */
trips_zip AS (
    SELECT
        /* e.g.  40.758,-73.988  →  '40.758,-73.988'                     */
        CONCAT( TO_VARCHAR(ROUND(lat ,3)) , ',' , TO_VARCHAR(ROUND(lon,3)) )  AS zip ,
        pickup_hr                                                          AS hr ,
        COUNT(*)                                                           AS trip_cnt
    FROM raw_trips
    GROUP BY zip , hr
),

/* 3)  Complete grid of every (zip × hour) observed in the 21-day window */
all_zips AS ( SELECT DISTINCT zip FROM trips_zip ),
all_hrs  AS ( SELECT DISTINCT hr  FROM trips_zip ),
zip_hr_grid AS (
    SELECT z.zip , h.hr
    FROM   all_zips z
    CROSS  JOIN all_hrs h
),

/* 4)  Fill missing combinations with zero trips                       */
zip_hr_filled AS (
    SELECT
        g.zip ,
        g.hr ,
        COALESCE(t.trip_cnt , 0) AS trip_cnt
    FROM zip_hr_grid g
    LEFT JOIN trips_zip t
           ON t.zip = g.zip
          AND t.hr  = g.hr
),

/* 5)  Lags and rolling statistics (exclude current row)               */
enriched AS (
    SELECT
        zip ,
        hr ,
        trip_cnt ,

        /* lagged counts */
        LAG(trip_cnt , 1  ) OVER (PARTITION BY zip ORDER BY hr) AS trip_cnt_1h_ago ,
        LAG(trip_cnt , 24 ) OVER (PARTITION BY zip ORDER BY hr) AS trip_cnt_24h_ago ,
        LAG(trip_cnt , 168) OVER (PARTITION BY zip ORDER BY hr) AS trip_cnt_7d_ago  ,
        LAG(trip_cnt , 336) OVER (PARTITION BY zip ORDER BY hr) AS trip_cnt_14d_ago ,

        /* 14-day (336 h) and 21-day (504 h) moving stats */
        AVG(trip_cnt)         OVER (PARTITION BY zip ORDER BY hr
                                    ROWS BETWEEN 336 PRECEDING AND 1 PRECEDING) AS mov_avg_14d ,
        STDDEV_SAMP(trip_cnt) OVER (PARTITION BY zip ORDER BY hr
                                    ROWS BETWEEN 336 PRECEDING AND 1 PRECEDING) AS mov_std_14d ,
        AVG(trip_cnt)         OVER (PARTITION BY zip ORDER BY hr
                                    ROWS BETWEEN 504 PRECEDING AND 1 PRECEDING) AS mov_avg_21d ,
        STDDEV_SAMP(trip_cnt) OVER (PARTITION BY zip ORDER BY hr
                                    ROWS BETWEEN 504 PRECEDING AND 1 PRECEDING) AS mov_std_21d
    FROM zip_hr_filled
)

/* 6)  Return 1-Jan-2015 hours, top-5 (zip , hour) by trip count       */
SELECT
    zip        AS "zip_code" ,
    hr         AS "pickup_hour" ,
    trip_cnt   AS "trip_cnt" ,
    trip_cnt_1h_ago ,
    trip_cnt_24h_ago ,
    trip_cnt_7d_ago ,
    trip_cnt_14d_ago ,
    mov_avg_14d ,
    mov_std_14d ,
    mov_avg_21d ,
    mov_std_21d
FROM   enriched
WHERE  hr BETWEEN '2015-01-01 00:00:00'::TIMESTAMP_NTZ
           AND  '2015-01-01 23:00:00'::TIMESTAMP_NTZ
ORDER  BY trip_cnt DESC NULLS LAST
LIMIT 5;