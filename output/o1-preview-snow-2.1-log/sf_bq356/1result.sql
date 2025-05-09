SELECT COUNT(*) AS "Number_of_Stations"
FROM (
    SELECT "stn", "wban"
    FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2019"
    WHERE "temp" IS NOT NULL
    GROUP BY "stn", "wban"
    HAVING COUNT(*) >= 329
) AS tc
JOIN "NOAA_DATA"."NOAA_GSOD"."STATIONS" AS s
ON tc."stn" = s."usaf" AND tc."wban" = s."wban"
WHERE s."begin" <= '20000101' AND s."end" >= '20190630';