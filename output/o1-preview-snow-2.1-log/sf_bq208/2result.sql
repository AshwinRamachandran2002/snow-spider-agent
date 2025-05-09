SELECT
    s."usaf" AS station_id,
    s."name" AS station_name,
    ROUND(s."lon", 4) AS longitude,
    ROUND(s."lat", 4) AS latitude,
    COUNT(g."temp") AS number_of_valid_temp_observations
FROM "NEW_YORK_NOAA"."NOAA_GSOD"."STATIONS" s
JOIN (
    SELECT "stn", "wban", "temp" FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2011"
    UNION ALL SELECT "stn", "wban", "temp" FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2012"
    UNION ALL SELECT "stn", "wban", "temp" FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2013"
    UNION ALL SELECT "stn", "wban", "temp" FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2014"
    UNION ALL SELECT "stn", "wban", "temp" FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2015"
    UNION ALL SELECT "stn", "wban", "temp" FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2016"
    UNION ALL SELECT "stn", "wban", "temp" FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2017"
    UNION ALL SELECT "stn", "wban", "temp" FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2018"
    UNION ALL SELECT "stn", "wban", "temp" FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2019"
    UNION ALL SELECT "stn", "wban", "temp" FROM "NEW_YORK_NOAA"."NOAA_GSOD"."GSOD2020"
) g
ON s."usaf" = g."stn" AND s."wban" = g."wban"
WHERE
    g."temp" IS NOT NULL AND
    s."lat" IS NOT NULL AND
    s."lon" IS NOT NULL AND
    ST_DWITHIN(
        ST_MAKEPOINT(s."lon", s."lat"),
        ST_MAKEPOINT(-73.764, 41.197),
        32186.88
    )
GROUP BY
    s."usaf",
    s."name",
    s."lon",
    s."lat"
ORDER BY
    number_of_valid_temp_observations DESC NULLS LAST;