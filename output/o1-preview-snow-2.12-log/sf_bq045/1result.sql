SELECT
    CONCAT(s."usaf", s."wban") AS "station_id",
    s."name" AS "station_name",
    rainy_2023."rainy_days_2023",
    rainy_2022."rainy_days_2022"
FROM "NOAA_DATA"."NOAA_GSOD"."STATIONS" s
JOIN (
    SELECT "stn", "wban", COUNT(*) AS "rainy_days_2023"
    FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2023"
    WHERE "prcp" > 0 AND "prcp" != 99.99
    GROUP BY "stn", "wban"
) rainy_2023 ON s."usaf" = rainy_2023."stn" AND s."wban" = rainy_2023."wban"
JOIN (
    SELECT "stn", "wban", COUNT(*) AS "rainy_days_2022"
    FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2022"
    WHERE "prcp" > 0 AND "prcp" != 99.99
    GROUP BY "stn", "wban"
) rainy_2022 ON s."usaf" = rainy_2022."stn" AND s."wban" = rainy_2022."wban"
WHERE s."state" = 'WA'
  AND rainy_2023."rainy_days_2023" > 150
  AND rainy_2023."rainy_days_2023" < rainy_2022."rainy_days_2022"
ORDER BY rainy_2023."rainy_days_2023" DESC NULLS LAST;