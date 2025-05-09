WITH stations AS (   -- add distance from Chappaqua to every station
    SELECT
        "usaf",
        "wban",
        "name",
        "lat",
        "lon",
        ST_DISTANCE( ST_POINT("lon","lat"), ST_POINT(-73.764 , 41.197) ) AS dist_m
    FROM NEW_YORK_NOAA.NOAA_GSOD.STATIONS
    WHERE "lat" IS NOT NULL
      AND "lon" IS NOT NULL
),
near_stations AS (   -- keep stations within 20-mile (32 186.88 m) radius
    SELECT "usaf","wban","name","lat","lon"
    FROM stations
    WHERE dist_m <= 32186.88
),
all_years AS (       -- temperature rows for 2011-2020
    SELECT "stn","temp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2011 UNION ALL
    SELECT "stn","temp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2012 UNION ALL
    SELECT "stn","temp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2013 UNION ALL
    SELECT "stn","temp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2014 UNION ALL
    SELECT "stn","temp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2015 UNION ALL
    SELECT "stn","temp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2016 UNION ALL
    SELECT "stn","temp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2017 UNION ALL
    SELECT "stn","temp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2018 UNION ALL
    SELECT "stn","temp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2019 UNION ALL
    SELECT "stn","temp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2020
)
SELECT
    ns."usaf"       AS "STATION_USAF",
    ns."wban"       AS "WBAN",
    TRIM(ns."name") AS "STATION_NAME",
    ns."lat"        AS "LATITUDE",
    ns."lon"        AS "LONGITUDE",
    COUNT(*)        AS "VALID_TEMP_OBSERVATIONS_2011_2020"
FROM near_stations ns
JOIN all_years ay
  ON ay."stn" = ns."usaf"
WHERE ay."temp" <> 9999.9          -- discard missing/invalid temperature values
GROUP BY
    ns."usaf",
    ns."wban",
    ns."name",
    ns."lat",
    ns."lon"
ORDER BY
    "VALID_TEMP_OBSERVATIONS_2011_2020" DESC NULLS LAST;