WITH filtered_trips AS (
    SELECT
        t."pickup_location_id",
        /* tip rate expressed as % – treat total_amount = 0 as zero tip rate */
        CASE
            WHEN t."total_amount" > 0 THEN (t."tip_amount" * 100) / t."total_amount"
            ELSE 0
        END AS "tip_rate"
    FROM NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TLC_YELLOW_TRIPS_2016 t
    WHERE
        /* trips whose PU & DO occur 01-01-2016 through 01-07-2016 (inclusive)          */
        t."pickup_datetime"  >= 1451606400000000   -- 2016-01-01 00:00:00
        AND t."pickup_datetime"  < 1452211200000000 -- 2016-01-08 00:00:00
        AND t."dropoff_datetime" >= 1451606400000000
        AND t."dropoff_datetime" < 1452211200000000
        /* logical trip and quality filters                                            */
        AND t."dropoff_datetime" > t."pickup_datetime"
        AND t."passenger_count"  > 0
        AND t."trip_distance"    >= 0
        AND t."tip_amount"       >= 0
        AND t."tolls_amount"     >= 0
        AND t."mta_tax"          >= 0
        AND t."fare_amount"      >= 0
        AND t."total_amount"     >= 0
),
trips_with_borough AS (
    SELECT
        z."borough",
        f."tip_rate"
    FROM filtered_trips f
    JOIN NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TAXI_ZONE_GEOM z
      ON f."pickup_location_id" = z."zone_id"
)
SELECT
    "borough"            AS "pickup_borough",
    ROUND(
        SUM(CASE WHEN "tip_rate" = 0 THEN 1 ELSE 0 END) * 100.0
        / COUNT(*),
    2)                   AS "pct_no_tip"
FROM trips_with_borough
GROUP BY "borough"
ORDER BY "pct_no_tip" DESC NULLS LAST;