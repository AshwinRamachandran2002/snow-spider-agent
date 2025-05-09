SELECT s."usaf" AS "Station_ID", s."name" AS "Station_Name"
FROM "NOAA_DATA"."NOAA_GSOD"."STATIONS" s
JOIN (
    SELECT "stn", COUNT(*) AS "rainy_days_2023"
    FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2023"
    WHERE "prcp" > 0 AND "prcp" < 99.99
    GROUP BY "stn"
) rd2023 ON s."usaf" = rd2023."stn"
JOIN (
    SELECT "stn", COUNT(*) AS "rainy_days_2022"
    FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2022"
    WHERE "prcp" > 0 AND "prcp" < 99.99
    GROUP BY "stn"
) rd2022 ON s."usaf" = rd2022."stn"
WHERE s."state" = 'WA'
  AND rd2023."rainy_days_2023" > 150
  AND rd2023."rainy_days_2023" < rd2022."rainy_days_2022";