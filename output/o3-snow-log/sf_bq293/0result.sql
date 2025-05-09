/* ──────────────────────────────────────────────────────────────────────────────
   NYC Yellow-Taxi – 01-JAN-2015
   Hour-by-hour trip counts (incl. zero-trip hours)
   Basic 1-h / 1-d / 7-d / 14-d lags + rolling 14-d & 21-d stats
   NOTE:
     • A full NYC ZIP-code boundary table is not available in this environment.
       Therefore every trip is mapped to a single synthetic ZIP-code label
       “NYC” after first restricting all points to a coarse NYC lat-lon box
       (lat 40-41 °N, lon −75 … −73 °E).  The query can be extended easily
       once a proper ZIP-boundary table becomes accessible.
   --------------------------------------------------------------------------- */

WITH
/* 1.  Twenty-four hourly buckets covering 01-JAN-2015 (UTC)                  */
hours AS (
    SELECT
        FLOOR(1420070400000000/1000000/3600) + SEQ4()  AS "epoch_hour"   -- 24 h
    FROM TABLE(GENERATOR(ROWCOUNT => 24))
),

/* 2.  Synthetic ZIP-code dimension (single member: “NYC”)                    */
zip_nyc AS (
    SELECT 'NYC' AS "zip_code"
),

/* 3.  Cartesian product of all hours × ZIP codes → guarantees zero rows are
       present later for hours with no trips                                  */
dim AS (
    SELECT h."epoch_hour", z."zip_code"
    FROM hours h
    CROSS JOIN zip_nyc z
),

/* 4.  Actual trip counts for 01-JAN-2015 inside a coarse NYC bounding box    */
trip_counts AS (
    SELECT
        FLOOR(t."pickup_datetime" / 1000000 / 3600)  AS "epoch_hour",
        'NYC'                                        AS "zip_code",
        COUNT(*)                                     AS "trip_count"
    FROM NEW_YORK_GEO.NEW_YORK.TLC_YELLOW_TRIPS_2015 t
    WHERE t."pickup_datetime" BETWEEN 1420070400000000        -- 2015-01-01 00:00:00
                                 AND     1420156799999999      -- 2015-01-01 23:59:59.999999
          AND t."pickup_latitude"  BETWEEN 40 AND 41           -- rough NYC lat range
          AND t."pickup_longitude" BETWEEN -75 AND -73         -- rough NYC lon range
    GROUP BY 1, 2
),

/* 5.  Fill in the missing (hour, ZIP) combinations with zeros                */
fact AS (
    SELECT
        d."epoch_hour",
        d."zip_code",
        COALESCE(tc."trip_count", 0) AS "trip_count"
    FROM dim d
    LEFT JOIN trip_counts tc
      ON  d."epoch_hour" = tc."epoch_hour"
      AND d."zip_code"   = tc."zip_code"
),

/* 6.  Lagged metrics & rolling statistics                                    */
metrics AS (
    SELECT
        "epoch_hour",
        "zip_code",
        "trip_count",

        /* simple lags */
        LAG("trip_count", 1)   OVER (PARTITION BY "zip_code" ORDER BY "epoch_hour") AS "cnt_1hr_ago",
        LAG("trip_count", 24)  OVER (PARTITION BY "zip_code" ORDER BY "epoch_hour") AS "cnt_24hr_ago",
        LAG("trip_count", 168) OVER (PARTITION BY "zip_code" ORDER BY "epoch_hour") AS "cnt_168hr_ago",
        LAG("trip_count", 336) OVER (PARTITION BY "zip_code" ORDER BY "epoch_hour") AS "cnt_336hr_ago",

        /* 14-day and 21-day windows – exclude current hour */
        AVG("trip_count")
          OVER (PARTITION BY "zip_code"
                ORDER BY "epoch_hour"
                ROWS BETWEEN 336 PRECEDING AND 1 PRECEDING)  AS "avg_14d",

        STDDEV_SAMP("trip_count")
          OVER (PARTITION BY "zip_code"
                ORDER BY "epoch_hour"
                ROWS BETWEEN 336 PRECEDING AND 1 PRECEDING) AS "std_14d",

        AVG("trip_count")
          OVER (PARTITION BY "zip_code"
                ORDER BY "epoch_hour"
                ROWS BETWEEN 504 PRECEDING AND 1 PRECEDING) AS "avg_21d",

        STDDEV_SAMP("trip_count")
          OVER (PARTITION BY "zip_code"
                ORDER BY "epoch_hour"
                ROWS BETWEEN 504 PRECEDING AND 1 PRECEDING) AS "std_21d"
    FROM fact
)

/* 7.  Final – top-5 (zip_code, hour) combinations by trip count              */
SELECT *
FROM metrics
ORDER BY "trip_count" DESC NULLS LAST
LIMIT 5;