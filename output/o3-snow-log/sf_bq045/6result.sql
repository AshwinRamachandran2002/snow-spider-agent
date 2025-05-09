/*  Weather stations in Washington (US-WA) that
    • logged >150 “rainy days” during calendar-year 2023
    • but had fewer rainy days in 2023 than in 2022.

    “Rainy day”  = PRCP > 0 mm   AND PRCP <> 99.99 (sentinel for missing/trace).
*/
WITH rainy_2023 AS (   -- count rainy days in 2023
    SELECT
        g."stn"  AS "usaf",
        g."wban",
        COUNT(*) AS "days_2023"
    FROM NOAA_DATA.NOAA_GSOD."GSOD2023" g
    JOIN NOAA_DATA.NOAA_GSOD."STATIONS" s
      ON g."stn"  = s."usaf"
     AND g."wban" = s."wban"
    WHERE s."country" = 'US'
      AND s."state"   = 'WA'
      AND g."prcp" <> 99.99          -- valid precip data
      AND g."prcp"  > 0              -- actually rained
    GROUP BY g."stn", g."wban"
),
rainy_2022 AS (   -- count rainy days in 2022
    SELECT
        g."stn"  AS "usaf",
        g."wban",
        COUNT(*) AS "days_2022"
    FROM NOAA_DATA.NOAA_GSOD."GSOD2022" g
    JOIN NOAA_DATA.NOAA_GSOD."STATIONS" s
      ON g."stn"  = s."usaf"
     AND g."wban" = s."wban"
    WHERE s."country" = 'US'
      AND s."state"   = 'WA'
      AND g."prcp" <> 99.99
      AND g."prcp"  > 0
    GROUP BY g."stn", g."wban"
)

SELECT
    st."name"              AS "station_name",
    r23."usaf"             AS "station_usaf",
    r23."wban"             AS "station_wban",
    r23."days_2023",
    r22."days_2022"
FROM rainy_2023 r23
JOIN rainy_2022 r22
  ON r23."usaf" = r22."usaf"
 AND r23."wban" = r22."wban"
JOIN NOAA_DATA.NOAA_GSOD."STATIONS" st
  ON st."usaf" = r23."usaf"
 AND st."wban" = r23."wban"
WHERE r23."days_2023" > 150          -- >150 rainy days in 2023
  AND r23."days_2023" < r22."days_2022"  -- fewer than in 2022
ORDER BY r23."days_2023" DESC NULLS LAST;