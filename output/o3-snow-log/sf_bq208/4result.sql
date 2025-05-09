WITH stations AS (   -- compute great-circle distance to Chappaqua
    SELECT
        "usaf",
        "wban",
        TRIM("name")              AS "name",
        "lat",
        "lon",
        3959 * acos(              -- haversine distance (miles)
               LEAST(1,
                     cos(radians(41.197))
                   * cos(radians("lat"))
                   * cos(radians("lon") - radians(-73.764))
                   + sin(radians(41.197))
                   * sin(radians("lat"))
               )
        )                         AS distance_miles           -- << unquoted alias
    FROM NEW_YORK_NOAA.NOAA_GSOD."STATIONS"
),
nearby AS (        -- keep only stations ≤ 20 miles
    SELECT *
    FROM stations
    WHERE distance_miles <= 20
),
-- combine GSOD daily files 2011-2020 and keep only valid temps
obs AS (
    SELECT "stn", "wban", "temp"
    FROM (
        SELECT "stn","wban","temp" FROM NEW_YORK_NOAA.NOAA_GSOD."GSOD2011" UNION ALL
        SELECT "stn","wban","temp" FROM NEW_YORK_NOAA.NOAA_GSOD."GSOD2012" UNION ALL
        SELECT "stn","wban","temp" FROM NEW_YORK_NOAA.NOAA_GSOD."GSOD2013" UNION ALL
        SELECT "stn","wban","temp" FROM NEW_YORK_NOAA.NOAA_GSOD."GSOD2014" UNION ALL
        SELECT "stn","wban","temp" FROM NEW_YORK_NOAA.NOAA_GSOD."GSOD2015" UNION ALL
        SELECT "stn","wban","temp" FROM NEW_YORK_NOAA.NOAA_GSOD."GSOD2016" UNION ALL
        SELECT "stn","wban","temp" FROM NEW_YORK_NOAA.NOAA_GSOD."GSOD2017" UNION ALL
        SELECT "stn","wban","temp" FROM NEW_YORK_NOAA.NOAA_GSOD."GSOD2018" UNION ALL
        SELECT "stn","wban","temp" FROM NEW_YORK_NOAA.NOAA_GSOD."GSOD2019" UNION ALL
        SELECT "stn","wban","temp" FROM NEW_YORK_NOAA.NOAA_GSOD."GSOD2020"
    )
    WHERE "temp" IS NOT NULL
      AND "temp" <> 9999.9        -- exclude missing/invalid
)
SELECT
    n."usaf"                             AS "USAF",
    n."wban"                             AS "WBAN",
    n."name"                             AS "STATION_NAME",
    ROUND(n."lat",4)                     AS "LATITUDE",
    ROUND(n."lon",4)                     AS "LONGITUDE",
    ROUND(n.distance_miles,2)            AS "DIST_MILES",
    COUNT(o."temp")                      AS "VALID_TEMP_OBS_2011_2020"
FROM nearby n
LEFT JOIN obs o
       ON o."stn"  = n."usaf"
      AND o."wban" = n."wban"
GROUP BY
    n."usaf", n."wban", n."name",
    n."lat", n."lon", n.distance_miles
ORDER BY "VALID_TEMP_OBS_2011_2020" DESC NULLS LAST;