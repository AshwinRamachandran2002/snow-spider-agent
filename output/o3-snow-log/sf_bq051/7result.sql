/*  Average daily CitiBike trips in 2016 – Rainy (>5 mm) vs Non-Rainy days     */
/*  Uses New York Central Park station (USW00094728), which has complete data   */

WITH rain AS (                       -- daily rain flag from Central Park station
    SELECT
        "date",
        CASE WHEN SUM("value") > 50            -- raw > 50  ⇒  >5 mm
             THEN 'Rainy' ELSE 'Non-Rainy' END AS "rain_flag"
    FROM   NEW_YORK_GHCN.GHCN_D.GHCND_2016
    WHERE  "id"      = 'USW00094728'           -- Central Park, NY
      AND  "element" = 'PRCP'
      AND  "qflag"  IS NULL                   -- keep only good records
    GROUP  BY "date"
),

bike AS (                       -- daily CitiBike trip totals for calendar 2016
    SELECT
        DATE_TRUNC('day', TO_TIMESTAMP_NTZ("starttime"/1000000))::DATE AS "date",
        COUNT(*)                                                      AS "daily_trips"
    FROM   NEW_YORK_GHCN.NEW_YORK.CITIBIKE_TRIPS
    WHERE  "starttime" >= 1451606400000000      -- 2016-01-01 00:00:00
      AND  "starttime" <  1483228800000000      -- 2017-01-01 00:00:00
    GROUP  BY 1
)

-- combine and calculate average trips
SELECT
    r."rain_flag",
    AVG(b."daily_trips") AS "avg_daily_trips"
FROM  bike b
JOIN  rain r  ON r."date" = b."date"
GROUP BY r."rain_flag"
ORDER BY r."rain_flag";