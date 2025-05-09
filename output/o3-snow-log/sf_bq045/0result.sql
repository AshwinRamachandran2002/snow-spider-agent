/*  Stations in Washington (WA) that
    • recorded >150 “rainy days” in 2023
    • but had fewer rainy days in 2023 than in 2022
    (“rainy day” = PRCP > 0 mm and PRCP ≠ 99.99)            */
WITH rain_2023 AS (
    SELECT g23."stn"            AS "usaf",
           COUNT(*)             AS "rainy_2023"
    FROM   NOAA_DATA.NOAA_GSOD.GSOD2023  g23
           JOIN NOAA_DATA.NOAA_GSOD.STATIONS s23
             ON g23."stn" = s23."usaf"
    WHERE  s23."state" = 'WA'
      AND  g23."prcp" != 99.99          -- ignore “missing” flag
      AND  g23."prcp"  > 0              -- >0 mm = rainy
    GROUP BY g23."stn"
),
rain_2022 AS (
    SELECT g22."stn"            AS "usaf",
           COUNT(*)             AS "rainy_2022"
    FROM   NOAA_DATA.NOAA_GSOD.GSOD2022  g22
           JOIN NOAA_DATA.NOAA_GSOD.STATIONS s22
             ON g22."stn" = s22."usaf"
    WHERE  s22."state" = 'WA'
      AND  g22."prcp" != 99.99
      AND  g22."prcp"  > 0
    GROUP BY g22."stn"
)
SELECT   s."usaf"                           AS "station_code",
         TRIM(s."name")                     AS "station_name",
         r23."rainy_2023",
         r22."rainy_2022"
FROM     rain_2023 r23
         JOIN rain_2022 r22  ON r23."usaf" = r22."usaf"
         JOIN NOAA_DATA.NOAA_GSOD.STATIONS s
           ON s."usaf" = r23."usaf"
WHERE    r23."rainy_2023" > 150            -- >150 rainy days in 2023
  AND    r23."rainy_2023" < r22."rainy_2022"  -- fewer than in 2022
ORDER BY r23."rainy_2023" DESC NULLS LAST;