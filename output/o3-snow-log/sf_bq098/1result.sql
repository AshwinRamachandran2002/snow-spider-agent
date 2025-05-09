WITH filtered AS (
    SELECT
        z."borough"                    AS "pickup_borough",
        t."tip_amount",
        t."total_amount"
    FROM NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS."TLC_YELLOW_TRIPS_2016" t
    JOIN NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS."TAXI_ZONE_GEOM"        z
          ON z."zone_id" = t."pickup_location_id"
    WHERE  t."pickup_datetime"  IS NOT NULL
      AND  t."dropoff_datetime" IS NOT NULL
      AND  t."dropoff_datetime" >  t."pickup_datetime"                       -- drop-after-pickup
      AND  TO_DATE(TO_TIMESTAMP_NTZ(t."pickup_datetime" / 1000000))
                 BETWEEN '2016-01-01' AND '2016-01-07'
      AND  TO_DATE(TO_TIMESTAMP_NTZ(t."dropoff_datetime" / 1000000))
                 BETWEEN '2016-01-01' AND '2016-01-07'
      AND  t."passenger_count"   > 0
      AND  t."trip_distance"     >= 0
      AND  t."tip_amount"        >= 0
      AND  t."tolls_amount"      >= 0
      AND  t."mta_tax"           >= 0
      AND  t."fare_amount"       >= 0
      AND  t."total_amount"      >= 0
),
tip_calc AS (
    SELECT
        "pickup_borough",
        CASE
            WHEN "total_amount" = 0 THEN 0
            ELSE ("tip_amount" * 100) / "total_amount"
        END AS "tip_rate"
    FROM filtered
)
SELECT
    "pickup_borough",
    ROUND(
        100.0 * SUM(CASE WHEN "tip_rate" = 0 THEN 1 ELSE 0 END) / COUNT(*),
        4
    ) AS "pct_no_tip"
FROM tip_calc
GROUP BY "pickup_borough"
ORDER BY "pickup_borough";