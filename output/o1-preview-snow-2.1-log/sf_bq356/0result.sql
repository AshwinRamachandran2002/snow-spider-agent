SELECT COUNT(*) AS "Number_of_Stations"
FROM (
    SELECT v."stn", v."wban"
    FROM (
        SELECT g."stn", g."wban", COUNT(*) AS "valid_temp_days"
        FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2019" g
        WHERE g."temp" IS NOT NULL
        GROUP BY g."stn", g."wban"
    ) v
    JOIN (
        SELECT s."usaf" AS "stn", s."wban"
        FROM "NOAA_DATA"."NOAA_GSOD"."STATIONS" s
        WHERE TO_DATE(s."begin", 'YYYYMMDD') <= '2000-01-01'
          AND TO_DATE(s."end", 'YYYYMMDD') >= '2019-06-30'
    ) s
    ON v."stn" = s."stn" AND v."wban" = s."wban"
    WHERE v."valid_temp_days" >= 329
) AS t;