/*--------------------------------------------------------------------
  Proportion of NYC yellow-cab rides in each tip category
  (pickup dates 2016-01-01 through 2016-01-07, inclusive),
  by pickup borough – excluding Staten Island and EWR.
--------------------------------------------------------------------*/
WITH filtered_trips AS (   -- keep only valid rides that meet all rules
    SELECT
        t."tip_amount"    AS TIP_AMOUNT,
        t."total_amount"  AS TOTAL_AMOUNT,
        z."borough"       AS PICKUP_BOROUGH
    FROM  NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TLC_YELLOW_TRIPS_2016   t
    JOIN  NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS.TAXI_ZONE_GEOM          z
          ON t."pickup_location_id" = z."zone_id"
    WHERE t."pickup_datetime" >= 1451606400000000    -- 2016-01-01 00:00:00
      AND t."pickup_datetime" <  1452211200000000    -- 2016-01-08 00:00:00
      AND t."dropoff_datetime" >  t."pickup_datetime"
      AND t."passenger_count"  >  0
      AND t."trip_distance"    >= 0
      AND t."fare_amount"      >= 0
      AND t."mta_tax"          >= 0
      AND t."tolls_amount"     >= 0
      AND t."tip_amount"       >= 0
      AND t."total_amount"     >= 0
      AND z."borough" NOT IN ('EWR', 'Staten Island')
),
tip_rates AS (              -- compute tip % (base = total – tip)
    SELECT
        PICKUP_BOROUGH,
        CASE
            WHEN TOTAL_AMOUNT - TIP_AMOUNT = 0 THEN 0
            ELSE 100 * TIP_AMOUNT / (TOTAL_AMOUNT - TIP_AMOUNT)
        END AS TIP_RATE
    FROM filtered_trips
),
bucketed AS (               -- assign each ride to a bucket
    SELECT
        PICKUP_BOROUGH,
        CASE
            WHEN TIP_RATE = 0                      THEN 'no tip'
            WHEN TIP_RATE <= 5                     THEN 'Less than 5%'
            WHEN TIP_RATE > 5  AND TIP_RATE <= 10  THEN '5% to 10%'
            WHEN TIP_RATE > 10 AND TIP_RATE <= 15  THEN '10% to 15%'
            WHEN TIP_RATE > 15 AND TIP_RATE <= 20  THEN '15% to 20%'
            WHEN TIP_RATE > 20 AND TIP_RATE <= 25  THEN '20% to 25%'
            ELSE                                        'More than 25%'
        END AS TIP_BUCKET
    FROM tip_rates
),
counts AS (                 -- count rides per borough & bucket
    SELECT
        PICKUP_BOROUGH,
        TIP_BUCKET,
        COUNT(*) AS RIDES
    FROM bucketed
    GROUP BY PICKUP_BOROUGH, TIP_BUCKET
)
SELECT
    PICKUP_BOROUGH,
    TIP_BUCKET,
    ROUND(
        RIDES * 1.0
        / SUM(RIDES) OVER (PARTITION BY PICKUP_BOROUGH),
        4
    ) AS PROPORTION
FROM counts
ORDER BY PICKUP_BOROUGH, TIP_BUCKET;