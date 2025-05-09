WITH "NEARBY_STATIONS" AS (
    /* find stations within 20-mile great-circle distance of Chappaqua, NY (41.197,-73.764) */
    SELECT
        "usaf",
        "wban",
        "name",
        "state",
        "lat",
        "lon",
        /* haversine distance in miles (earth-radius ≈ 3959 mi) */
        3959 * 2 * ASIN(
              SQRT(
                     POWER( SIN( RADIANS( ("lat" - 41.197) / 2 ) ), 2 )
                   + COS( RADIANS( 41.197 ) )
                   * COS( RADIANS( "lat" ) )
                   * POWER( SIN( RADIANS( ("lon" - ( -73.764 ) ) / 2 ) ), 2 )
              )
        )                                 AS "distance_miles"
    FROM NEW_YORK_NOAA.NOAA_GSOD.STATIONS
    WHERE "lat" IS NOT NULL
      AND "lon" IS NOT NULL
)
SELECT
    s."usaf"                                              AS "station_usaf",
    s."name"                                              AS "station_name",
    s."lat"                                               AS "latitude",
    s."lon"                                               AS "longitude",
    COUNT(*)                                              AS "valid_temp_obs_2011_2020"
FROM "NEARBY_STATIONS"  s
JOIN (
          /* union all GSOD tables from 2011-2020, keeping only valid (≠9999.9) temperatures */
          SELECT "stn" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2011 WHERE "temp" <> 9999.9
          UNION ALL
          SELECT "stn" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2012 WHERE "temp" <> 9999.9
          UNION ALL
          SELECT "stn" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2013 WHERE "temp" <> 9999.9
          UNION ALL
          SELECT "stn" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2014 WHERE "temp" <> 9999.9
          UNION ALL
          SELECT "stn" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2015 WHERE "temp" <> 9999.9
          UNION ALL
          SELECT "stn" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2016 WHERE "temp" <> 9999.9
          UNION ALL
          SELECT "stn" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2017 WHERE "temp" <> 9999.9
          UNION ALL
          SELECT "stn" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2018 WHERE "temp" <> 9999.9
          UNION ALL
          SELECT "stn" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2019 WHERE "temp" <> 9999.9
          UNION ALL
          SELECT "stn" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2020 WHERE "temp" <> 9999.9
     ) t
       ON s."usaf" = t."stn"
WHERE s."distance_miles" <= 20
GROUP BY
    s."usaf",
    s."name",
    s."lat",
    s."lon"
ORDER BY
    "valid_temp_obs_2011_2020" DESC NULLS LAST;