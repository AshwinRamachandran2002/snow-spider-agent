/*  Weather stations in Washington (US-WA) that
    – logged >150 rainy days in 2023, and
    – logged fewer rainy days in 2023 than in 2022.
    A “rainy day” is one where "prcp" > 0 and <> 99.99 (valid precip reported). */

WITH  -- 2023 rainy-day counts per station
rainy23 AS (
    SELECT  g."stn"  AS "usaf",
            g."wban",
            COUNT(*) AS "days_2023"
    FROM    "NOAA_DATA"."NOAA_GSOD"."GSOD2023" g
    JOIN    "NOAA_DATA"."NOAA_GSOD"."STATIONS" s
            ON  s."usaf" = g."stn"
            AND s."wban" = g."wban"
    WHERE   s."country" = 'US'
      AND   s."state"   = 'WA'
      AND   g."prcp"   <> 99.99      -- valid precip
      AND   g."prcp"    > 0          -- a rainy day
    GROUP BY g."stn", g."wban"
),

-- 2022 rainy-day counts per station
rainy22 AS (
    SELECT  g."stn"  AS "usaf",
            g."wban",
            COUNT(*) AS "days_2022"
    FROM    "NOAA_DATA"."NOAA_GSOD"."GSOD2022" g
    JOIN    "NOAA_DATA"."NOAA_GSOD"."STATIONS" s
            ON  s."usaf" = g."stn"
            AND s."wban" = g."wban"
    WHERE   s."country" = 'US'
      AND   s."state"   = 'WA'
      AND   g."prcp"   <> 99.99
      AND   g."prcp"    > 0
    GROUP BY g."stn", g."wban"
)

SELECT  s."usaf",
        s."wban",
        RTRIM(s."name")                       AS "station_name",
        r23."days_2023",
        r22."days_2022"
FROM        rainy23 r23
JOIN        rainy22 r22
       ON   r22."usaf" = r23."usaf"
      AND   r22."wban" = r23."wban"
JOIN        "NOAA_DATA"."NOAA_GSOD"."STATIONS" s
       ON   s."usaf"   = r23."usaf"
      AND   s."wban"   = r23."wban"
WHERE       r23."days_2023" > 150          -- more than 150 rainy days in 2023
  AND       r23."days_2023" < r22."days_2022"  -- but fewer than in 2022
ORDER BY    r23."days_2023" DESC NULLS LAST;