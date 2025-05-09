/*  Weather-stations in Washington (state = 'WA') that  
    – logged >150 “rainy days” during 2023 (prcp > 0 & <> 99.99)  
    – but had FEWER rainy days in 2023 than in 2022.           */

WITH rainy_2023 AS (   -- count 2023 rainy days per station
    SELECT
        g."stn",
        g."wban",
        COUNT(*) AS "rainy_2023"
    FROM NOAA_DATA.NOAA_GSOD."GSOD2023"  g
    JOIN NOAA_DATA.NOAA_GSOD."STATIONS"  s
      ON g."stn"  = s."usaf"
     AND g."wban" = s."wban"
    WHERE s."state" = 'WA'
      AND g."prcp" <> 99.99   -- exclude missing / trace
      AND g."prcp"  > 0       -- rainy day
    GROUP BY g."stn", g."wban"
),
rainy_2022 AS (        -- count 2022 rainy days per station
    SELECT
        g."stn",
        g."wban",
        COUNT(*) AS "rainy_2022"
    FROM NOAA_DATA.NOAA_GSOD."GSOD2022"  g
    JOIN NOAA_DATA.NOAA_GSOD."STATIONS"  s
      ON g."stn"  = s."usaf"
     AND g."wban" = s."wban"
    WHERE s."state" = 'WA'
      AND g."prcp" <> 99.99
      AND g."prcp"  > 0
    GROUP BY g."stn", g."wban"
)

SELECT
    r23."stn"        AS "usaf",
    r23."wban",
    s."name"         AS "station_name",
    r23."rainy_2023",
    r22."rainy_2022"
FROM rainy_2023 r23
JOIN rainy_2022 r22
  ON r23."stn"  = r22."stn"
 AND r23."wban" = r22."wban"
JOIN NOAA_DATA.NOAA_GSOD."STATIONS" s
  ON s."usaf" = r23."stn"
 AND s."wban" = r23."wban"
WHERE r23."rainy_2023" > 150          -- >150 rainy days in 2023
  AND r23."rainy_2023" < r22."rainy_2022"  -- fewer than in 2022
ORDER BY r23."rainy_2023" DESC NULLS LAST;