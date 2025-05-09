/* -----------------------------------------------------------------
   Average daily Citi Bike trips in 2016 on Rainy (>5 mm) versus
   Non-Rainy days, using the closest GHCN station with complete
   data inside 50 km of NYC (JFK Intl – id USW00094728, ≈21 km).
-------------------------------------------------------------------*/
WITH daily_prcp AS (   /* 2016 daily precipitation at JFK airport */
    SELECT
        g."date",
        SUM(g."value") / 10.0              AS precip_mm          -- convert to mm
    FROM NEW_YORK_GHCN.GHCN_D.GHCND_2016 g
    WHERE g."id"      = 'USW00094728'      -- JFK International Airport
      AND g."element" = 'PRCP'
      AND g."qflag"  IS NULL               -- keep only un-flagged data
    GROUP BY g."date"
),

daily_trips AS (       /* 2016 daily CitiBike trip counts */
    SELECT
        TO_DATE(TO_TIMESTAMP("starttime" / 1000000))  AS "date",
        COUNT(*)                                      AS trips
    FROM NEW_YORK_GHCN.NEW_YORK.CITIBIKE_TRIPS
    WHERE "starttime" BETWEEN 1451606400000000        -- 2016-01-01 00:00:00
                          AND 1483228799000000        -- 2016-12-31 23:59:59
    GROUP BY 1
)

SELECT
    CASE WHEN p.precip_mm > 5
         THEN 'Rainy'
         ELSE 'Non-Rainy'
    END                               AS rain_flag,
    AVG(t.trips)                      AS avg_daily_citibike_trips_2016
FROM   daily_prcp  p
JOIN   daily_trips t
       ON p."date" = t."date"
GROUP  BY 1
ORDER  BY 1;