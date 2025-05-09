/* ------------------------------------------------------------
   Proportion of 2016-01-01‒2016-01-07 yellow-cab rides in each
   tip-percentage bucket, by PICK-UP borough (excluding EWR and
   Staten Island pick-ups)
   ------------------------------------------------------------ */
WITH base AS (   -- all qualifying trips with a valid pick-up borough
    SELECT
        z."borough"                                             AS pickup_borough,
        t."tip_amount",
        t."total_amount"
    FROM NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS."TLC_YELLOW_TRIPS_2016" t
    JOIN NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS."TAXI_ZONE_GEOM"       z
          ON t."pickup_location_id" = z."zone_id"
    WHERE
          /* week of 1-Jan-2016 through 7-Jan-2016 (NYC local) */
          t."pickup_datetime" BETWEEN 1451606400000000     -- 2016-01-01 00:00:00
                                   AND 1452211199999999     -- 2016-01-07 23:59:59
      AND t."dropoff_datetime"   >  t."pickup_datetime"     -- logical trip
      AND t."passenger_count"    >  0
      /* non-negative monetary / distance fields */
      AND t."trip_distance"      >= 0
      AND t."tip_amount"         >= 0
      AND t."tolls_amount"       >= 0
      AND t."mta_tax"            >= 0
      AND t."fare_amount"        >= 0
      AND t."total_amount"       >= 0
      /* exclude EWR & Staten Island pick-ups */
      AND z."borough" NOT IN ('EWR','Staten Island')
),
bucketed AS (    -- assign each trip to a tip-percentage bucket
    SELECT
        pickup_borough,
        CASE
            WHEN "tip_amount" = 0 THEN 'no tip'
            /* avoid division by zero when total – tip = 0 */
            WHEN "total_amount" - "tip_amount" = 0 THEN 'no tip'
            ELSE
                CASE
                    WHEN 100*"tip_amount"/("total_amount" - "tip_amount") <= 5
                        THEN 'Less than 5%'
                    WHEN 100*"tip_amount"/("total_amount" - "tip_amount") <= 10
                        THEN '5% to 10%'
                    WHEN 100*"tip_amount"/("total_amount" - "tip_amount") <= 15
                        THEN '10% to 15%'
                    WHEN 100*"tip_amount"/("total_amount" - "tip_amount") <= 20
                        THEN '15% to 20%'
                    WHEN 100*"tip_amount"/("total_amount" - "tip_amount") <= 25
                        THEN '20% to 25%'
                    ELSE 'More than 25%'
                END
        END AS tip_bucket
    FROM base
)
SELECT
    pickup_borough,
    tip_bucket,
    /* proportion = bucket_count / total trips in borough */
    ROUND(
        COUNT(*)::FLOAT
        / SUM(COUNT(*)) OVER (PARTITION BY pickup_borough),
        4
    ) AS proportion
FROM bucketed
GROUP BY
    pickup_borough,
    tip_bucket
ORDER BY
    pickup_borough,
    tip_bucket;