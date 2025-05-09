/*  Weather stations in Washington (state = 'WA') that
    • recorded more than 150 “rainy days” in 2023
    • but had fewer rainy days in 2023 than in 2022.
      (“Rainy day” = precipitation > 0 mm and <> 99.99)  */

WITH rd_2023 AS (          -- rainy–day counts for 2023
    SELECT g."stn",
           g."wban",
           COUNT(*) AS "rainy_days_2023"
    FROM NOAA_DATA.NOAA_GSOD.GSOD2023         AS g
    JOIN NOAA_DATA.NOAA_GSOD.STATIONS         AS s
      ON g."stn"  = s."usaf"
     AND g."wban" = s."wban"
    WHERE s."state" = 'WA'
      AND g."prcp" <> 99.99          -- exclude missing values
      AND g."prcp"  > 0              -- actual precipitation
    GROUP BY g."stn", g."wban"
),
rd_2022 AS (          -- rainy–day counts for 2022
    SELECT g."stn",
           g."wban",
           COUNT(*) AS "rainy_days_2022"
    FROM NOAA_DATA.NOAA_GSOD.GSOD2022         AS g
    JOIN NOAA_DATA.NOAA_GSOD.STATIONS         AS s
      ON g."stn"  = s."usaf"
     AND g."wban" = s."wban"
    WHERE s."state" = 'WA'
      AND g."prcp" <> 99.99
      AND g."prcp"  > 0
    GROUP BY g."stn", g."wban"
)

SELECT  s."usaf"  AS "station_id",
        s."wban",
        s."name",
        rd23."rainy_days_2023",
        rd22."rainy_days_2022"
FROM rd_2023 rd23
JOIN rd_2022 rd22
  ON rd23."stn"  = rd22."stn"
 AND rd23."wban" = rd22."wban"
JOIN NOAA_DATA.NOAA_GSOD.STATIONS  AS s
  ON s."usaf" = rd23."stn"
 AND s."wban" = rd23."wban"
WHERE rd23."rainy_days_2023" > 150
  AND rd23."rainy_days_2023" < rd22."rainy_days_2022"
ORDER BY rd23."rainy_days_2023" DESC NULLS LAST;