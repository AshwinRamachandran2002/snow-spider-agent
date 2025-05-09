/*  Weather-stations ≤20 miles from Chappaqua, NY (41.197 , -73.764)
    with count of VALID (“temp” not null / 9999.9) observations
    between 2011-01-01 and 2020-12-31                                       */

WITH stations_near AS (   -- stations within 20-mile great-circle distance
    SELECT
        "usaf",
        "wban",
        TRIM("name")        AS "name",
        "lat",
        "lon"
    FROM NEW_YORK_NOAA.NOAA_GSOD.STATIONS
    WHERE "lat" IS NOT NULL
      AND "lon" IS NOT NULL
      AND 3958.8 * ACOS(                -- haversine (Earth radius ≈ 3958.8 mi)
              COS(RADIANS(41.197)) * COS(RADIANS("lat"))
            * COS(RADIANS("lon") - RADIANS(-73.764))
            + SIN(RADIANS(41.197)) * SIN(RADIANS("lat"))
          ) <= 20
),

gsod_2011_2020 AS (       -- all daily rows for 2011-2020
    SELECT "stn","wban","temp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2011 UNION ALL
    SELECT "stn","wban","temp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2012 UNION ALL
    SELECT "stn","wban","temp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2013 UNION ALL
    SELECT "stn","wban","temp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2014 UNION ALL
    SELECT "stn","wban","temp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2015 UNION ALL
    SELECT "stn","wban","temp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2016 UNION ALL
    SELECT "stn","wban","temp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2017 UNION ALL
    SELECT "stn","wban","temp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2018 UNION ALL
    SELECT "stn","wban","temp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2019 UNION ALL
    SELECT "stn","wban","temp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2020
)

SELECT
    s."usaf"                               AS "USAF",
    s."wban"                               AS "WBAN",
    s."name"                               AS "STATION_NAME",
    s."lat"                                AS "LATITUDE",
    s."lon"                                AS "LONGITUDE",
    COUNT(*)                               AS "VALID_TEMP_OBS_2011_2020"
FROM stations_near      s
JOIN gsod_2011_2020     g   ON g."stn" = s."usaf"  AND g."wban" = s."wban"
WHERE g."temp" IS NOT NULL
  AND g."temp" <> 9999.9                   -- exclude missing/invalid temps
GROUP BY
    s."usaf", s."wban", s."name", s."lat", s."lon"
ORDER BY "VALID_TEMP_OBS_2011_2020" DESC NULLS LAST;