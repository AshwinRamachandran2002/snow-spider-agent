SELECT s."usaf" AS "Station_ID", s."name" AS "Station_Name"
FROM "NOAA_DATA"."NOAA_GSOD"."STATIONS" AS s
INNER JOIN (
    SELECT gsod."stn", gsod."wban", COUNT(*) AS "rainy_days_2022"
    FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2022" AS gsod
    WHERE gsod."prcp" > 0 AND gsod."stn" != '999999'
    GROUP BY gsod."stn", gsod."wban"
) AS rains_2022 ON s."usaf" = rains_2022."stn" AND s."wban" = rains_2022."wban"
INNER JOIN (
    SELECT gsod."stn", gsod."wban", COUNT(*) AS "rainy_days_2023"
    FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2023" AS gsod
    WHERE gsod."prcp" > 0 AND gsod."stn" != '999999'
    GROUP BY gsod."stn", gsod."wban"
) AS rains_2023 ON s."usaf" = rains_2023."stn" AND s."wban" = rains_2023."wban"
WHERE s."state" = 'WA' AND s."usaf" != '999999'
  AND rains_2023."rainy_days_2023" > 150
  AND rains_2022."rainy_days_2022" > rains_2023."rainy_days_2023";