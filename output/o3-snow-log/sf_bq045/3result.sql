/*  Weather stations in Washington State that
    • logged >150 “rainy days” (PRCP > 0 & PRCP <> 99.99) in 2023
    • but logged fewer rainy days in 2023 than in 2022                                   */

WITH rainy_2023 AS (
    SELECT 
        g."stn",
        g."wban",
        COUNT(*) AS "rainy_days_2023"
    FROM NOAA_DATA.NOAA_GSOD."GSOD2023" AS g
    JOIN NOAA_DATA.NOAA_GSOD."STATIONS"  AS s
         ON g."stn"  = s."usaf"
        AND g."wban" = s."wban"
    WHERE s."state" = 'WA'               -- Washington stations only
      AND g."prcp" <> 99.99              -- exclude “no report / missing”
      AND g."prcp"  > 0                  -- define a “rainy day”
    GROUP BY g."stn", g."wban"
    HAVING COUNT(*) > 150                -- >150 rainy days in 2023
), rainy_2022 AS (
    SELECT 
        g."stn",
        g."wban",
        COUNT(*) AS "rainy_days_2022"
    FROM NOAA_DATA.NOAA_GSOD."GSOD2022" AS g
    JOIN NOAA_DATA.NOAA_GSOD."STATIONS"  AS s
         ON g."stn"  = s."usaf"
        AND g."wban" = s."wban"
    WHERE s."state" = 'WA'
      AND g."prcp" <> 99.99
      AND g."prcp"  > 0
    GROUP BY g."stn", g."wban"
)
SELECT
    r23."stn",
    r23."wban",
    r23."rainy_days_2023",
    COALESCE(r22."rainy_days_2022", 0) AS "rainy_days_2022"
FROM rainy_2023 AS r23
LEFT JOIN rainy_2022 AS r22
       ON r23."stn"  = r22."stn"
      AND r23."wban" = r22."wban"
WHERE r23."rainy_days_2023" < COALESCE(r22."rainy_days_2022", 0)
ORDER BY r23."rainy_days_2023" DESC NULLS LAST;