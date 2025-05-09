/*--------------------------------------------------------------------
  1)  Pick the single closest GHCN station that sits ≤ 50 km from the
      NYC reference point (40.7128 N , -74.0060 E).
  2)  Flag every 2016 day at that station as RAINY when precipitation
      > 5 mm  (raw “value” is in 1/10-mm, so > 50).
  3)  Count CitiBike trips for every NYC day in 2016.
  4)  Compare the average daily trip-counts for RAINY vs NOT_RAINY days.
--------------------------------------------------------------------*/
WITH nearest_station AS (    -------------------------------------------------- 1
    SELECT  "id"
    FROM    (
              SELECT  "id",
                      6371 * ACOS(        /* great-circle distance (km)       */
                            COS(RADIANS(40.7128))
                          * COS(RADIANS("latitude"))
                          * COS(RADIANS("longitude") - RADIANS(-74.0060))
                        + SIN(RADIANS(40.7128))
                          * SIN(RADIANS("latitude"))
                      )   AS distance_km
              FROM  NEW_YORK_GHCN.GHCN_D.GHCND_STATIONS
              WHERE "latitude"  BETWEEN 40.7128-0.6  AND 40.7128+0.6   /* ~67 km */
                AND "longitude" BETWEEN -74.0060-0.8 AND -74.0060+0.8
            )
    ORDER BY distance_km
    LIMIT 1
), prcp AS (                 -------------------------------------------------- 2
    SELECT  "date",
            CASE WHEN "value" > 50          /* >5 mm                          */
                 THEN 'RAINY' ELSE 'NOT_RAINY' END  AS "rain_flag"
    FROM    NEW_YORK_GHCN.GHCN_D.GHCND_2016
    WHERE   "id"      = (SELECT "id" FROM nearest_station)
      AND   "element" = 'PRCP'
      AND   "qflag"   IS NULL               /* keep only un-flagged data       */
), bike AS (                 -------------------------------------------------- 3
    SELECT  TO_DATE(TO_TIMESTAMP("starttime"/1000000))    AS "trip_date",
            COUNT(*)                                      AS "num_trips"
    FROM    NEW_YORK_GHCN.NEW_YORK.CITIBIKE_TRIPS
    WHERE   TO_DATE(TO_TIMESTAMP("starttime"/1000000))
            BETWEEN '2016-01-01' AND '2016-12-31'
    GROUP BY 1
)                           -------------------------------------------------- 4
SELECT  COALESCE(p."rain_flag", 'NOT_RAINY')              AS "rain_flag",
        ROUND(AVG(b."num_trips"), 2)                      AS "avg_daily_trips"
FROM    bike  b
LEFT    JOIN prcp p
          ON b."trip_date" = p."date"
GROUP BY 1
ORDER BY 1;