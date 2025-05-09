WITH close_stations AS (   -- 1. distance of each station from Chappaqua (41.197 N, -73.764 E)
    SELECT
        "usaf",
        "wban",
        TRIM("name")                    AS "name",
        "lat",
        "lon",
        ST_DISTANCE(
            ST_POINT("lon", "lat"),     -- station location
            ST_POINT(-73.764, 41.197)   -- Chappaqua location
        ) AS dist_m
    FROM NEW_YORK_NOAA.NOAA_GSOD.STATIONS
    WHERE "lat" IS NOT NULL
      AND "lon" IS NOT NULL
),
filtered_stations AS (     -- 2. only stations within 20-mile (≈32 186.9 m) radius
    SELECT *
    FROM close_stations
    WHERE dist_m <= 32186.9
),
gsod_2011_2020 AS (        -- 3. union all GSOD tables 2011-2020 (stn, wban, temp)
    SELECT "stn", "wban", "temp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2011 UNION ALL
    SELECT "stn", "wban", "temp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2012 UNION ALL
    SELECT "stn", "wban", "temp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2013 UNION ALL
    SELECT "stn", "wban", "temp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2014 UNION ALL
    SELECT "stn", "wban", "temp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2015 UNION ALL
    SELECT "stn", "wban", "temp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2016 UNION ALL
    SELECT "stn", "wban", "temp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2017 UNION ALL
    SELECT "stn", "wban", "temp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2018 UNION ALL
    SELECT "stn", "wban", "temp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2019 UNION ALL
    SELECT "stn", "wban", "temp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2020
)
-- 4. count valid (non-missing) temperature observations for each nearby station
SELECT
    fs."name"                                                        AS "station_name",
    fs."usaf",
    fs."wban",
    COUNT(g."temp")                                                  AS "valid_temperature_observations_2011_2020"
FROM filtered_stations fs
LEFT JOIN gsod_2011_2020 g
       ON TRIM(g."stn")  = TRIM(fs."usaf")
      AND TRIM(g."wban") = TRIM(fs."wban")
      AND g."temp" IS NOT NULL
      AND g."temp" <> 9999.9        -- exclude missing/invalid temperature values
GROUP BY fs."name", fs."usaf", fs."wban"
ORDER BY "valid_temperature_observations_2011_2020" DESC NULLS LAST;