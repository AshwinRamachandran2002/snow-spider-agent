/*  stations within 20-mile radius of Chappaqua (41.197 N, -73.764 W)
    and number of NON-missing daily temperature observations
    during 2011-2020                                           */

WITH temp_obs AS (           -- all GSOD daily rows for 2011-2020
    SELECT "stn" AS "usaf", "wban", "temp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2011
    UNION ALL SELECT "stn", "wban", "temp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2012
    UNION ALL SELECT "stn", "wban", "temp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2013
    UNION ALL SELECT "stn", "wban", "temp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2014
    UNION ALL SELECT "stn", "wban", "temp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2015
    UNION ALL SELECT "stn", "wban", "temp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2016
    UNION ALL SELECT "stn", "wban", "temp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2017
    UNION ALL SELECT "stn", "wban", "temp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2018
    UNION ALL SELECT "stn", "wban", "temp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2019
    UNION ALL SELECT "stn", "wban", "temp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2020
),
valid_obs AS (               -- count only valid (≠ 9999.9) temps
    SELECT "usaf",
           "wban",
           COUNT(*) AS "valid_temp_observations"
    FROM   temp_obs
    WHERE  "temp" IS NOT NULL
      AND  "temp" <> 9999.9
    GROUP  BY "usaf", "wban"
),
station_dist AS (            -- compute distance to Chappaqua
    SELECT  s."usaf",
            s."wban",
            TRIM(s."name")           AS "station_name",
            s."lat",
            s."lon",
            ST_DISTANCE(
                TO_GEOGRAPHY('POINT(-73.764 41.197)'),
                TO_GEOGRAPHY('POINT(' || s."lon" || ' ' || s."lat" || ')')
            ) AS "distance_meters"
    FROM    NEW_YORK_NOAA.NOAA_GSOD.STATIONS s
),
nearby AS (                   -- within 20 miles (≈32 186.88 m)
    SELECT * 
    FROM   station_dist
    WHERE  "distance_meters" <= 32186.88
)
SELECT  n."station_name",
        n."usaf",
        n."wban",
        ROUND(n."lat",4)  AS "latitude",
        ROUND(n."lon",4)  AS "longitude",
        v."valid_temp_observations"
FROM    nearby      n
JOIN    valid_obs   v
       ON n."usaf" = v."usaf"
      AND n."wban" = v."wban"
ORDER BY v."valid_temp_observations" DESC NULLS LAST,
         n."station_name";