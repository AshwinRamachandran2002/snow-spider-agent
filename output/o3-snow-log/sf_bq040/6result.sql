/*---------------------------------------------------------------
  Tip-bucket distribution for NYC yellow-cab trips picked up
  between 1-Jan-2016 and 7-Jan-2016 (inclusive)

  Filters applied
  • drop-off after pick-up
  • passenger_count  > 0
  • non–negative trip_distance, fare_amount, tip_amount,
    mta_tax, tolls_amount, total_amount
  • exclude pickups whose borough is “Staten Island”
    or whose zone_name contains “EWR”
----------------------------------------------------------------*/
WITH jan16_trips AS (   -- ① basic row-level filters & borough lookup
    SELECT  t."pickup_location_id",
            t."passenger_count",
            t."trip_distance",
            t."fare_amount",
            t."tip_amount",
            t."total_amount",
            t."tolls_amount",
            t."mta_tax",
            z."borough"
    FROM  "NEW_YORK_PLUS"."NEW_YORK_TAXI_TRIPS"."TLC_YELLOW_TRIPS_2016"  t
    JOIN  "NEW_YORK_PLUS"."NEW_YORK_TAXI_TRIPS"."TAXI_ZONE_GEOM"         z
          ON t."pickup_location_id" = z."zone_id"
    WHERE t."pickup_datetime" BETWEEN 1451606400000000 /* 2016-01-01 00:00 */
                                  AND 1452211199000000 /* 2016-01-07 23:59 */
      AND t."dropoff_datetime" > t."pickup_datetime"
      AND t."passenger_count" > 0
      AND t."trip_distance"   >= 0
      AND t."fare_amount"     >= 0
      AND t."tip_amount"      >= 0
      AND t."mta_tax"         >= 0
      AND t."tolls_amount"    >= 0
      AND t."total_amount"    >= 0
      AND z."borough" NOT ILIKE '%staten%'
      AND z."zone_name" NOT ILIKE '%ewr%'
), tip_buckets AS (     -- ② classify each trip into a tip-percentage band
    SELECT  "borough",
            CASE
                 WHEN "tip_amount" = 0 THEN 'no tip'
                 WHEN 100 * "tip_amount" /
                      NULLIF("total_amount" - "tip_amount", 0) <=  5 THEN 'Less than 5%'
                 WHEN 100 * "tip_amount" /
                      NULLIF("total_amount" - "tip_amount", 0) <= 10 THEN '5% to 10%'
                 WHEN 100 * "tip_amount" /
                      NULLIF("total_amount" - "tip_amount", 0) <= 15 THEN '10% to 15%'
                 WHEN 100 * "tip_amount" /
                      NULLIF("total_amount" - "tip_amount", 0) <= 20 THEN '15% to 20%'
                 WHEN 100 * "tip_amount" /
                      NULLIF("total_amount" - "tip_amount", 0) <= 25 THEN '20% to 25%'
                 ELSE 'More than 25%'
            END  AS tip_bucket
    FROM jan16_trips
)
SELECT
       "borough"                     AS pickup_borough,
       tip_bucket,
       COUNT(*)                      AS rides_in_bucket,
       ROUND( 100.0 * COUNT(*) 
              / SUM(COUNT(*)) OVER (PARTITION BY "borough"), 2) 
                                      AS pct_of_borough
FROM tip_buckets
GROUP BY
       "borough",
       tip_bucket
ORDER BY
       "borough",
       tip_bucket;