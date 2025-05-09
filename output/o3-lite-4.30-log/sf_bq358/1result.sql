WITH day_temp AS (
    SELECT MAX(CAST("temp" AS FLOAT)) AS "max_temp"
    FROM NEW_YORK_CITIBIKE_1.NOAA_GSOD.GSOD2015
    WHERE "wban" = '94728'
      AND "year" = '2015'
      AND "mo"   = '07'
      AND "da"   = '15'
),
trips_20150715 AS (
    SELECT *
    FROM NEW_YORK_CITIBIKE_1.NEW_YORK_CITIBIKE.CITIBIKE_TRIPS
    WHERE TO_DATE(TO_TIMESTAMP_LTZ("starttime" / 1000000)) = '2015-07-15'
),
trip_with_zips AS (
    SELECT
        zs."zip_code" AS "start_zip",
        ze."zip_code" AS "end_zip"
    FROM trips_20150715 t
    JOIN NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES.ZIP_CODES zs
      ON ST_CONTAINS(
           TO_GEOGRAPHY(zs."zip_code_geom"),
           TO_GEOGRAPHY('POINT(' || t."start_station_longitude" || ' ' || t."start_station_latitude" || ')')
         )
    JOIN NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES.ZIP_CODES ze
      ON ST_CONTAINS(
           TO_GEOGRAPHY(ze."zip_code_geom"),
           TO_GEOGRAPHY('POINT(' || t."end_station_longitude" || ' ' || t."end_station_latitude" || ')')
         )
)
SELECT
    "start_zip",
    "end_zip"
FROM trip_with_zips
QUALIFY ROW_NUMBER() OVER (
            ORDER BY TO_NUMBER("start_zip") ASC,
                     TO_NUMBER("end_zip") DESC
        ) = 1;