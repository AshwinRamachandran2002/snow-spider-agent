WITH gsod_data AS (
    SELECT "stn", "wban", "temp"
    FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2011"
    UNION ALL
    SELECT "stn", "wban", "temp"
    FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2012"
    UNION ALL
    SELECT "stn", "wban", "temp"
    FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2013"
    UNION ALL
    SELECT "stn", "wban", "temp"
    FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2014"
    UNION ALL
    SELECT "stn", "wban", "temp"
    FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2015"
    UNION ALL
    SELECT "stn", "wban", "temp"
    FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2016"
    UNION ALL
    SELECT "stn", "wban", "temp"
    FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2017"
    UNION ALL
    SELECT "stn", "wban", "temp"
    FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2018"
    UNION ALL
    SELECT "stn", "wban", "temp"
    FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2019"
    UNION ALL
    SELECT "stn", "wban", "temp"
    FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2020"
)
SELECT
    s."usaf" || '-' || s."wban" AS "station_id",
    s."name" AS "station_name",
    ROUND(CAST(s."lon" AS DOUBLE), 4) AS "longitude",
    ROUND(CAST(s."lat" AS DOUBLE), 4) AS "latitude",
    COUNT(gs."temp") AS "number_of_valid_temp_observations"
FROM
    "NEW_YORK_NOAA"."NOAA_GSOD"."STATIONS" AS s
JOIN
    gsod_data AS gs
    ON s."usaf" = gs."stn" AND s."wban" = gs."wban"
WHERE
    s."lat" IS NOT NULL
    AND s."lon" IS NOT NULL
    AND ST_DWITHIN(
        ST_POINT(CAST(s."lon" AS DOUBLE), CAST(s."lat" AS DOUBLE)),
        ST_POINT(-73.764, 41.197),
        32186.88  -- 20 miles in meters
    )
    AND gs."temp" IS NOT NULL
GROUP BY
    s."usaf",
    s."wban",
    s."name",
    s."lon",
    s."lat"
ORDER BY
    "number_of_valid_temp_observations" DESC NULLS LAST;