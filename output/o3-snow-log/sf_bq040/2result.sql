/*  Proportion of yellow-taxi rides in each tip-percentage bucket
    for pick-ups occurring 1-7 Jan 2016, by pickup-borough
    (excluding Staten Island and EWR pick-ups)                           */

WITH jan16_yellow AS (      -- all qualifying trips
    SELECT
        z."borough"                AS BOROUGH,
        (t."tip_amount" / NULLIF(t."total_amount",0)) * 100  AS TIP_PCT
    FROM NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS."TLC_YELLOW_TRIPS_2016"  t
    JOIN NEW_YORK_PLUS.NEW_YORK_TAXI_TRIPS."TAXI_ZONE_GEOM"         z
             ON t."pickup_location_id" = z."zone_id"
    WHERE t."pickup_datetime" BETWEEN 1451606400000000   -- 01-Jan-2016 00:00
                                 AND     1452211200000000 -- 08-Jan-2016 00:00
      AND z."borough" NOT IN ('Staten Island','EWR')     -- exclude
      AND t."dropoff_datetime"  >  t."pickup_datetime"
      AND t."passenger_count"   >  0
      AND t."trip_distance"     >= 0
      AND t."fare_amount"       >= 0
      AND t."tip_amount"        >= 0
      AND t."tolls_amount"      >= 0
      AND t."mta_tax"           >= 0
      AND t."total_amount"      >= 0
),

bucketed AS (               -- assign each ride to a tip bucket
    SELECT
        BOROUGH,
        CASE
            WHEN TIP_PCT IS NULL OR TIP_PCT = 0             THEN 'no tip'
            WHEN TIP_PCT <=  5                              THEN 'Less than 5%'
            WHEN TIP_PCT <= 10                              THEN '5% to 10%'
            WHEN TIP_PCT <= 15                              THEN '10% to 15%'
            WHEN TIP_PCT <= 20                              THEN '15% to 20%'
            WHEN TIP_PCT <= 25                              THEN '20% to 25%'
            ELSE                                                 'More than 25%'
        END AS TIP_BUCKET
    FROM jan16_yellow
)

SELECT
    BOROUGH,
    TIP_BUCKET,
    COUNT(*)                                                   AS RIDES,
    ROUND( COUNT(*) * 100.0
           / SUM(COUNT(*)) OVER (PARTITION BY BOROUGH) , 2)    AS PCT_OF_RIDES
FROM bucketed
GROUP BY BOROUGH, TIP_BUCKET
ORDER BY BOROUGH,
         CASE TIP_BUCKET
              WHEN 'no tip'        THEN 1
              WHEN 'Less than 5%'  THEN 2
              WHEN '5% to 10%'     THEN 3
              WHEN '10% to 15%'    THEN 4
              WHEN '15% to 20%'    THEN 5
              WHEN '20% to 25%'    THEN 6
              ELSE                      7   -- 'More than 25%'
         END;