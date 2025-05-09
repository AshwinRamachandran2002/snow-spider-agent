SELECT
    s."usaf" AS "station_id",
    s."name" AS "station_name",
    t2023."rainy_days_2023" AS "number_of_rainy_days_2023",
    t2022."rainy_days_2022" AS "number_of_rainy_days_2022"
FROM
    "NOAA_DATA"."NOAA_GSOD"."STATIONS" s
    JOIN (
        SELECT "stn", COUNT(*) AS "rainy_days_2023"
        FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2023"
        WHERE 
            "prcp" IS NOT NULL AND
            "prcp" != 99.99 AND
            "prcp" > 0
        GROUP BY "stn"
    ) t2023 ON s."usaf" = t2023."stn"
    JOIN (
        SELECT "stn", COUNT(*) AS "rainy_days_2022"
        FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2022"
        WHERE 
            "prcp" IS NOT NULL AND
            "prcp" != 99.99 AND
            "prcp" > 0
        GROUP BY "stn"
    ) t2022 ON s."usaf" = t2022."stn"
WHERE
    s."state" = 'WA' AND
    t2023."rainy_days_2023" > 150 AND
    t2023."rainy_days_2023" < t2022."rainy_days_2022"
ORDER BY
    s."usaf"
;