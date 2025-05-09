SELECT s."usaf" AS "Station_ID", s."name" AS "Station_Name"
FROM NOAA_DATA."NOAA_GSOD"."STATIONS" s
JOIN (
    SELECT "stn", "wban", COUNT(*) AS "rainy_days_2023"
    FROM NOAA_DATA."NOAA_GSOD"."GSOD2023"
    WHERE "prcp" IS NOT NULL AND "prcp" > 0
    GROUP BY "stn", "wban"
) rd23 ON s."usaf" = rd23."stn" AND s."wban" = rd23."wban"
JOIN (
    SELECT "stn", "wban", COUNT(*) AS "rainy_days_2022"
    FROM NOAA_DATA."NOAA_GSOD"."GSOD2022"
    WHERE "prcp" IS NOT NULL AND "prcp" > 0
    GROUP BY "stn", "wban"
) rd22 ON s."usaf" = rd22."stn" AND s."wban" = rd22."wban"
WHERE s."state" = 'WA'
  AND rd23."rainy_days_2023" > 150
  AND rd23."rainy_days_2023" < rd22."rainy_days_2022";