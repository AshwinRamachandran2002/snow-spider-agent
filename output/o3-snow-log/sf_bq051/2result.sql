/*  Compare Citi Bike demand on rainy vs. dry days (2016)
    – use the closest weather station (≤ 50 km) that actually has
      un-flagged PRCP records in 2016                                              */

WITH
params AS (                 -- Manhattan reference point
    SELECT 40.7128  AS "lat0",
           -74.0060 AS "lon0"
),

/* 1.  find the nearest station that contains ≥1 good PRCP record in 2016 */
candidate AS (
    SELECT DISTINCT
           s."id",
           s."latitude",
           s."longitude",
           /* great-circle distance in km */
           6371 * ACOS(
                   LEAST(1 ,
                         SIN(RADIANS(p."lat0")) * SIN(RADIANS(s."latitude"))
                       + COS(RADIANS(p."lat0")) * COS(RADIANS(s."latitude"))
                       * COS(RADIANS(s."longitude" - p."lon0"))
                   )
           ) AS "distance_km"
    FROM NEW_YORK_GHCN.GHCN_D.GHCND_STATIONS      s
    JOIN NEW_YORK_GHCN.GHCN_D.GHCND_INVENTORY     i
          ON i."id" = s."id"      AND i."element" = 'PRCP'
                                 AND 2016 BETWEEN i."firstyear" AND i."lastyear"
    /* ensure the station actually reports good PRCP rows in 2016                */
    JOIN NEW_YORK_GHCN.GHCN_D.GHCND_2016          g
          ON g."id"      = s."id"
         AND g."element" = 'PRCP'
         AND g."qflag"  IS NULL
    CROSS JOIN params p
    WHERE s."latitude"  IS NOT NULL
      AND s."longitude" IS NOT NULL
),

nearest AS (                -- the single closest one within 50 km
    SELECT "id"
    FROM   candidate
    WHERE  "distance_km" <= 50
    QUALIFY ROW_NUMBER() OVER (ORDER BY "distance_km") = 1
),

/* 2. daily precipitation flag (>5 mm ⇒ RAINY) for that station in 2016 */
precip_daily AS (
    SELECT
        g."date",
        CASE WHEN SUM(g."value") > 50          -- values are in 0.1 mm
             THEN 'RAINY'
             ELSE 'DRY'
        END AS "rain_flag"
    FROM NEW_YORK_GHCN.GHCN_D.GHCND_2016 g
    JOIN nearest n ON n."id" = g."id"
    WHERE g."element" = 'PRCP'
      AND g."qflag"  IS NULL
    GROUP BY g."date"
),

/* 3. Citi Bike trips per calendar day in 2016                */
bike_daily AS (
    SELECT
        DATEADD(
            'second',
            FLOOR(t."starttime" / 1000000),    -- µs-epoch  → seconds
            '1970-01-01'
        )::DATE             AS "ride_date",
        COUNT(*)            AS "trip_cnt"
    FROM NEW_YORK_GHCN.NEW_YORK.CITIBIKE_TRIPS t
    WHERE t."starttime" >= 1451606400000000     -- 2016-01-01
      AND t."starttime" <  1483228800000000     -- 2017-01-01
    GROUP BY "ride_date"
)

/* 4.  average trips on rainy vs. dry days                     */
SELECT
    p."rain_flag",
    AVG(b."trip_cnt") AS "avg_daily_trips"
FROM precip_daily p
JOIN bike_daily   b  ON b."ride_date" = p."date"
GROUP BY p."rain_flag"
ORDER BY p."rain_flag";