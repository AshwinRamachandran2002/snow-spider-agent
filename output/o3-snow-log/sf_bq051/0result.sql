/* ---------------------------------------------------------------
   Average Citi Bike usage on rainy vs. non-rainy 2016 days
   (rainy = daily precipitation > 5 mm) for New York City.
   -------------------------------------------------------------*/
WITH nearest_station AS (      -- ❶ pick the closest suitable GHCN station
    SELECT
        s."id",
        /* Haversine great-circle distance to (40.7128  -74.0060) in km */
        6371 * 2 * ASIN(
            SQRT( POWER(SIN((RADIANS(s."latitude")  - RADIANS(40.7128)) / 2),2)
                + COS(RADIANS(40.7128)) * COS(RADIANS(s."latitude"))
                * POWER(SIN((RADIANS(s."longitude") - RADIANS(-74.0060)) / 2),2) )
        )                                                   AS "dist_km",
        ROW_NUMBER() OVER (
            ORDER BY
                6371 * 2 * ASIN(
                    SQRT( POWER(SIN((RADIANS(s."latitude")  - RADIANS(40.7128)) / 2),2)
                        + COS(RADIANS(40.7128)) * COS(RADIANS(s."latitude"))
                        * POWER(SIN((RADIANS(s."longitude") - RADIANS(-74.0060)) / 2),2) )
                )
        )                                                   AS "rn"
    FROM NEW_YORK_GHCN.GHCN_D.GHCND_STATIONS          s
    WHERE
          /* within 50 km of NYC */
          6371 * 2 * ASIN(
              SQRT( POWER(SIN((RADIANS(s."latitude")  - RADIANS(40.7128)) / 2),2)
                  + COS(RADIANS(40.7128)) * COS(RADIANS(s."latitude"))
                  * POWER(SIN((RADIANS(s."longitude") - RADIANS(-74.0060)) / 2),2) )
          ) < 50
      /* and has precipitation data that cover 2016 */
      AND s."id" IN (
          SELECT "id"
          FROM NEW_YORK_GHCN.GHCN_D.GHCND_INVENTORY
          WHERE "element" = 'PRCP'
            AND "firstyear" <= 2016
            AND "lastyear"  >= 2016
      )
),
chosen_station AS (            -- keep the single nearest one
    SELECT "id"  FROM nearest_station  WHERE "rn" = 1
),
/* ❷ Daily precipitation classification (RAINY / NON_RAINY) */
precip_2016 AS (
    SELECT
        p."date"                                        AS "day",
        CASE WHEN (p."value" / 10.0) > 5
             THEN 'RAINY' ELSE 'NON_RAINY' END          AS "rain_flag"
    FROM NEW_YORK_GHCN.GHCN_D.GHCND_2016            p
    JOIN chosen_station                              c  ON p."id" = c."id"
    WHERE p."element" = 'PRCP'              -- precipitation rows only
      AND p."qflag"  IS NULL                -- keep only un-flagged data
),
/* ❸ Daily Citi Bike trip counts for calendar year 2016 */
daily_bike_2016 AS (
    SELECT
        TO_DATE( TO_TIMESTAMP( "starttime" / 1000000 ) )   AS "day",
        COUNT(*)                                           AS "trips"
    FROM NEW_YORK_GHCN.NEW_YORK.CITIBIKE_TRIPS
    WHERE "starttime" BETWEEN 1451606400000000     /* 2016-01-01 00:00:00 */
                         AND     1483228799000000  /* 2016-12-31 23:59:59 */
    GROUP BY "day"
),
/* ❹ Join bike counts with rain flag */
bike_vs_rain AS (
    SELECT
        d."trips",
        p."rain_flag"
    FROM daily_bike_2016  d
    JOIN precip_2016      p  ON d."day" = p."day"
),
/* ❺ Average trips per day for each weather class */
avg_trips AS (
    SELECT
        "rain_flag",
        AVG("trips") AS "avg_daily_trips"
    FROM bike_vs_rain
    GROUP BY "rain_flag"
)
/* ❻ Present results side-by-side */
SELECT
    MAX(CASE WHEN "rain_flag" = 'RAINY'      THEN "avg_daily_trips" END)
        AS "avg_trips_rainy_days",
    MAX(CASE WHEN "rain_flag" = 'NON_RAINY'  THEN "avg_daily_trips" END)
        AS "avg_trips_non_rainy_days"
FROM avg_trips;