WITH weather AS (   -- Central Park (WBAN 94728) – mean temperature on 15-Jul-2015
    SELECT MAX("temp") AS "max_temp"
    FROM   NEW_YORK_CITIBIKE_1.NOAA_GSOD."GSOD2015"
    WHERE  "wban" = '94728'
      AND  "year" = '2015'
      AND  "mo"   = '07'
      AND  "da"   = '15'
),
trip_zips AS (      -- Citi Bike trips on 15-Jul-2015 with mapped START/END ZIPs
    SELECT
           t."starttime",
           start_zip."zip_code" AS "start_zip",
           end_zip."zip_code"   AS "end_zip"
    FROM   NEW_YORK_CITIBIKE_1.NEW_YORK_CITIBIKE."CITIBIKE_TRIPS"        t
    JOIN   NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES."ZIP_CODES" start_zip
           ON  ST_WITHIN(
                   ST_MAKEPOINT(t."start_station_longitude",
                                t."start_station_latitude"),
                   TO_GEOGRAPHY(start_zip."zip_code_geom"))
    JOIN   NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES."ZIP_CODES" end_zip
           ON  ST_WITHIN(
                   ST_MAKEPOINT(t."end_station_longitude",
                                t."end_station_latitude"),
                   TO_GEOGRAPHY(end_zip."zip_code_geom"))
    WHERE  t."starttime" BETWEEN 1436918400000000  -- 2015-07-15 00:00:00 (NYC)
                           AND     1437004799000000  -- 2015-07-15 23:59:59
)
SELECT
       "start_zip",
       "end_zip"
FROM   trip_zips, weather      -- every ZIP shares the same (max) temperature
ORDER  BY TO_NUMBER("start_zip") ASC,
          TO_NUMBER("end_zip")   DESC
LIMIT  1;