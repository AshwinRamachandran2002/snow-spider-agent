/*  Hour-by-hour NYC yellow-cab demand on 1-Jan-2015
    – counts, lags, moving averages & stdevs – per “ZIP-like” spatial cell */

---------------------------------------------------------------------------
/* 1) Build the 360-hour time axis  (14-day look-back + 1-Jan-2015)        */
WITH hours AS (
    SELECT
        DATEADD(
            hour,
            seq4(),                                    -- 0 … 359
            TO_TIMESTAMP('2014-12-18 00:00:00')        -- 336 h before 2015-01-01
        ) AS "hour_ts"
    FROM TABLE(GENERATOR(ROWCOUNT => 360))
),

/* 2) Pull raw trips in that 14-day window, keeping only “reasonable” NYC
       coordinates                                                         */
raw_trips AS (
    SELECT
        TO_TIMESTAMP("pickup_datetime" / 1000000) AS "pickup_ts",
        "pickup_longitude"                        AS "lon",
        "pickup_latitude"                         AS "lat"
    FROM NEW_YORK_GEO.NEW_YORK.TLC_YELLOW_TRIPS_2015
    WHERE "pickup_datetime" BETWEEN 1420070400000000 - 336*3600000000  -- 14 d back
                              AND     1420156800000000                 -- 1-Jan-2015 24:00
      AND "pickup_longitude" BETWEEN -75 AND -71
      AND "pickup_latitude"  BETWEEN  40 AND  42
),

/* 3) Assign each trip to a “ZIP-like” spatial cell
       (2-decimal grid ≈ ~1.1 km, adequate for demo when ZIP polygons
        are unavailable in current Snowflake environment)                 */
trips_with_zip AS (
    SELECT
        TO_VARCHAR(ROUND("lat", 2)) || ',' || TO_VARCHAR(ROUND("lon", 2)) 
            AS "zip_code",
        DATE_TRUNC('hour', "pickup_ts") AS "hour_ts"
    FROM raw_trips
),

/* 4) Distinct grid cells (= “zip codes”) found in the 14-day window       */
zips AS (
    SELECT DISTINCT "zip_code" FROM trips_with_zip
),

/* 5) Cartesian product of every grid cell × every hour                    */
grid AS (
    SELECT
        z."zip_code",
        h."hour_ts"
    FROM zips  z
    CROSS JOIN hours h
),

/* 6) Hourly trip counts per grid cell                                     */
agg AS (
    SELECT
        "zip_code",
        "hour_ts",
        COUNT(*) AS "trips"
    FROM trips_with_zip
    GROUP BY 1,2
),

/* 7) Fill missing hour/cell combos with zero                              */
filled AS (
    SELECT
        g."zip_code",
        g."hour_ts",
        COALESCE(a."trips", 0) AS "trips"
    FROM grid g
    LEFT JOIN agg a
           ON g."zip_code" = a."zip_code"
          AND g."hour_ts"  = a."hour_ts"
),

/* 8) Compute lags and moving statistics                                   */
metrics AS (
    SELECT
        "zip_code",
        "hour_ts",
        "trips",
        LAG("trips",   1) OVER (PARTITION BY "zip_code" ORDER BY "hour_ts") AS "trips_1hr_ago",
        LAG("trips",  24) OVER (PARTITION BY "zip_code" ORDER BY "hour_ts") AS "trips_24hr_ago",
        LAG("trips", 168) OVER (PARTITION BY "zip_code" ORDER BY "hour_ts") AS "trips_7d_ago",
        LAG("trips", 336) OVER (PARTITION BY "zip_code" ORDER BY "hour_ts") AS "trips_14d_ago",
        AVG   ("trips")   OVER (PARTITION BY "zip_code"
                                ORDER BY "hour_ts"
                                ROWS BETWEEN 336 PRECEDING AND 1 PRECEDING) AS "ma_14d",
        AVG   ("trips")   OVER (PARTITION BY "zip_code"
                                ORDER BY "hour_ts"
                                ROWS BETWEEN 504 PRECEDING AND 1 PRECEDING) AS "ma_21d",
        STDDEV("trips")   OVER (PARTITION BY "zip_code"
                                ORDER BY "hour_ts"
                                ROWS BETWEEN 336 PRECEDING AND 1 PRECEDING) AS "std_14d"
    FROM filled
),

/* 9) Keep only the 24 hours of 1-Jan-2015                                  */
final AS (
    SELECT *
    FROM metrics
    WHERE "hour_ts" BETWEEN '2015-01-01 00:00:00'::TIMESTAMP
                        AND '2015-01-01 23:59:59'::TIMESTAMP
)

/* 10) Return the five busiest (cell, hour) combos                         */
SELECT *
FROM final
ORDER BY "trips" DESC NULLS LAST
LIMIT 5;