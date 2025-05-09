WITH trips_2018 AS (
    /* All trips that STARTED in calendar year 2018 */
    SELECT
        "start_station_id",
        "start_station_name",
        TO_TIMESTAMP("starttime" / 1000000)              AS ts                -- convert µs → sec → timestamp
    FROM NEW_YORK_PLUS.NEW_YORK_CITIBIKE.CITIBIKE_TRIPS
    WHERE ts BETWEEN '2018-01-01' AND '2018-12-31 23:59:59.999'
),
top_station AS (
    /* Identify the single station with the most trip starts in 2018 */
    SELECT
        "start_station_id",
        "start_station_name",
        COUNT(*) AS trip_cnt
    FROM trips_2018
    GROUP BY 1,2
    ORDER BY trip_cnt DESC NULLS LAST
    LIMIT 1
),
target_trips AS (
    /* Trips from that top station only */
    SELECT
        ts,
        DAYOFWEEK(ts)           AS dow,     -- 0 = Sunday … 6 = Saturday in Snowflake
        DATE_PART('HOUR', ts)   AS hr
    FROM trips_2018 t
    JOIN top_station s
      ON t."start_station_id" = s."start_station_id"
),
peak_dow AS (
    /* Day-of-week with the most trips */
    SELECT dow
    FROM target_trips
    GROUP BY dow
    ORDER BY COUNT(*) DESC NULLS LAST
    LIMIT 1
),
peak_hr AS (
    /* Hour of day with the most trips */
    SELECT hr
    FROM target_trips
    GROUP BY hr
    ORDER BY COUNT(*) DESC NULLS LAST
    LIMIT 1
)
SELECT
    (SELECT dow FROM peak_dow) AS "PEAK_DAY_OF_WEEK",
    (SELECT hr  FROM peak_hr)  AS "PEAK_HOUR_OF_DAY";