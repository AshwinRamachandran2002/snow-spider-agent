/*  Average daily Citi Bike trips in 2016 on rainy (> 5 mm) versus non-rainy days,
    using Central Park weather station (id = 'USW00094728').              */

WITH daily_weather AS (                     -- rain flag for each 2016 day
    SELECT  g."date"                                   AS "ride_date",
            SUM(g."value") / 10.0                      AS "prcp_mm",
            CASE WHEN SUM(g."value") / 10.0 > 5
                 THEN 'rainy' ELSE 'non_rainy' END     AS "rain_flag"
    FROM    NEW_YORK_GHCN.GHCN_D.GHCND_2016 g
    WHERE   g."id"      = 'USW00094728'        -- Central Park
      AND   g."element" = 'PRCP'
      AND   g."qflag"   IS NULL                -- use only valid measurements
    GROUP   BY g."date"
),

daily_trips AS (                          -- Citi Bike trips per day in 2016
    SELECT  TO_DATE(TO_TIMESTAMP_NTZ(cb."starttime" / 1000000)) AS "ride_date",
            COUNT(*)                                           AS "daily_trips"
    FROM    NEW_YORK_GHCN.NEW_YORK.CITIBIKE_TRIPS cb
    WHERE   TO_DATE(TO_TIMESTAMP_NTZ(cb."starttime" / 1000000))
            BETWEEN '2016-01-01' AND '2016-12-31'
    GROUP   BY TO_DATE(TO_TIMESTAMP_NTZ(cb."starttime" / 1000000))
)

SELECT  dw."rain_flag",
        ROUND(AVG(dt."daily_trips"), 2) AS "avg_daily_trips"
FROM    daily_trips   dt
JOIN    daily_weather dw
       ON dt."ride_date" = dw."ride_date"
GROUP   BY dw."rain_flag"
ORDER   BY dw."rain_flag";