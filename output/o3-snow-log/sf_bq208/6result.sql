WITH candidate_stations AS (
    SELECT
        "usaf",
        "wban",
        "name",
        "lat",
        "lon",
        2 * 3958.8 * ASIN(
              SQRT(
                   POWER(SIN(RADIANS("lat" - 41.197) / 2), 2)
                 + COS(RADIANS(41.197))
                 * COS(RADIANS("lat"))
                 * POWER(SIN(RADIANS("lon" - (-73.764)) / 2), 2)
              )
        ) AS "distance_miles"
    FROM NEW_YORK_NOAA.NOAA_GSOD.STATIONS
    WHERE "lat" IS NOT NULL
      AND "lon" IS NOT NULL
),
temp_obs AS (
    SELECT
        "stn"  AS "usaf",
        "wban",
        COUNT(*) AS "valid_temp_count"
    FROM (
        SELECT "stn", "wban" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2011 WHERE "temp" <> 9999.9
        UNION ALL
        SELECT "stn", "wban" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2012 WHERE "temp" <> 9999.9
        UNION ALL
        SELECT "stn", "wban" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2013 WHERE "temp" <> 9999.9
        UNION ALL
        SELECT "stn", "wban" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2014 WHERE "temp" <> 9999.9
        UNION ALL
        SELECT "stn", "wban" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2015 WHERE "temp" <> 9999.9
        UNION ALL
        SELECT "stn", "wban" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2016 WHERE "temp" <> 9999.9
        UNION ALL
        SELECT "stn", "wban" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2017 WHERE "temp" <> 9999.9
        UNION ALL
        SELECT "stn", "wban" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2018 WHERE "temp" <> 9999.9
        UNION ALL
        SELECT "stn", "wban" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2019 WHERE "temp" <> 9999.9
        UNION ALL
        SELECT "stn", "wban" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2020 WHERE "temp" <> 9999.9
    ) AS unioned_years
    GROUP BY "stn", "wban"
)

SELECT
    cs."name"                                   AS "station_name",
    cs."usaf",
    cs."wban",
    ROUND(cs."distance_miles", 2)               AS "distance_miles",
    COALESCE(tobs."valid_temp_count", 0)        AS "valid_temperature_observations_2011_2020"
FROM   candidate_stations cs
LEFT   JOIN temp_obs tobs
       ON  cs."usaf" = tobs."usaf"
       AND cs."wban" = tobs."wban"
WHERE  cs."distance_miles" <= 20
ORDER  BY cs."distance_miles" ASC;