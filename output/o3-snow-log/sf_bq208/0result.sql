WITH station_filtered AS (
    /* 1.  Find stations within 20-mile radius of Chappaqua, NY (41.197, -73.764) */
    SELECT
        s."usaf",
        s."wban",
        TRIM(s."name")                 AS "station_name",
        s."lat",
        s."lon"
    FROM NEW_YORK_NOAA.NOAA_GSOD.STATIONS AS s
    WHERE s."lat" IS NOT NULL
      AND s."lon" IS NOT NULL
      /* great–circle distance in miles (Earth radius ≈ 3958.8 mi) */
      AND 3958.8 * 2 * ASIN(
              SQRT(
                  POWER( SIN( (RADIANS(s."lat") - RADIANS(41.197)) / 2 ), 2 )
                + COS( RADIANS(41.197) )
                  * COS( RADIANS(s."lat") )
                  * POWER( SIN( (RADIANS(s."lon") - RADIANS(-73.764)) / 2 ), 2 )
              )
          ) <= 20
),          

gsod_2011_2020 AS (
    /* 2.  All GSOD rows (2011-2020) that have **valid** temperature data */
    SELECT "stn", "wban", "count_temp"
      FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2011  WHERE "temp" <> 9999.9
    UNION ALL
    SELECT "stn", "wban", "count_temp"
      FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2012  WHERE "temp" <> 9999.9
    UNION ALL
    SELECT "stn", "wban", "count_temp"
      FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2013  WHERE "temp" <> 9999.9
    UNION ALL
    SELECT "stn", "wban", "count_temp"
      FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2014  WHERE "temp" <> 9999.9
    UNION ALL
    SELECT "stn", "wban", "count_temp"
      FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2015  WHERE "temp" <> 9999.9
    UNION ALL
    SELECT "stn", "wban", "count_temp"
      FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2016  WHERE "temp" <> 9999.9
    UNION ALL
    SELECT "stn", "wban", "count_temp"
      FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2017  WHERE "temp" <> 9999.9
    UNION ALL
    SELECT "stn", "wban", "count_temp"
      FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2018  WHERE "temp" <> 9999.9
    UNION ALL
    SELECT "stn", "wban", "count_temp"
      FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2019  WHERE "temp" <> 9999.9
    UNION ALL
    SELECT "stn", "wban", "count_temp"
      FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2020  WHERE "temp" <> 9999.9
)

SELECT
    sf."station_name",
    sf."usaf",
    sf."wban",
    sf."lat",
    sf."lon",
    SUM(g."count_temp") AS "valid_temperature_observations_2011_2020"
FROM station_filtered AS sf
JOIN gsod_2011_2020  AS g
  ON g."stn"  = sf."usaf"
 AND g."wban" = sf."wban"
GROUP BY
    sf."station_name",
    sf."usaf",
    sf."wban",
    sf."lat",
    sf."lon"
ORDER BY
    "valid_temperature_observations_2011_2020" DESC NULLS LAST;