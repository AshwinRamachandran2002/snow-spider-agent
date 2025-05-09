/*  Average Citi Bike trips on Rainy (> 5 mm) vs. Non-Rainy 2016 days       */
/*  Central Park weather station (USW00094728) – known to have full data    */

WITH wx AS (                                   -- daily precipitation & rain flag
    SELECT
        "date",
        SUM("value") / 10.0                             AS "prcp_mm",
        CASE WHEN SUM("value") / 10.0 > 5
             THEN 'Rainy' ELSE 'Non-Rainy' END          AS "rain_flag"
    FROM NEW_YORK_GHCN.GHCN_D.GHCND_2016
    WHERE "id"      = 'USW00094728'                     -- Central Park
      AND "element" = 'PRCP'
      AND "qflag"  IS NULL                              -- keep only valid data
    GROUP BY "date"
),
cb AS (                                   -- daily Citi Bike trip counts (2016)
    SELECT
        DATE_FROM_PARTS(1970, 1, 1)
          + FLOOR("starttime" / 1000000 / 86400)        AS "date",
        COUNT(*)                                        AS "daily_trips"
    FROM NEW_YORK_GHCN.NEW_YORK.CITIBIKE_TRIPS
    WHERE "starttime" BETWEEN 1451606400000000          -- 2016-01-01 00:00:00
                         AND     1483228799000000       -- 2016-12-31 23:59:59
    GROUP BY 1
)
SELECT
    wx."rain_flag"            AS "day_type",
    AVG(cb."daily_trips")     AS "avg_daily_trips"
FROM cb
JOIN wx USING ("date")        -- keep only days with weather data
GROUP BY wx."rain_flag"
ORDER BY wx."rain_flag";