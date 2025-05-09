WITH cp_weather AS (   -- Central Park weather on 2015-07-15
    SELECT "temp"
    FROM  "NEW_YORK_CITIBIKE_1"."NOAA_GSOD"."GSOD2015"
    WHERE "wban" = '94728'
      AND "year" = '2015'
      AND "mo"   = '07'
      AND "da"   = '15'
), ny_zips AS (        -- New-York-State ZIP geometries
    SELECT
        "zip_code",
        TO_GEOGRAPHY("zip_code_geom") AS geom
    FROM  "NEW_YORK_CITIBIKE_1"."GEO_US_BOUNDARIES"."ZIP_CODES"
    WHERE "state_code" = 'NY'
), trip_day AS (       -- All Citi Bike trips that started 2015-07-15
    SELECT
        "start_station_latitude",
        "start_station_longitude",
        "end_station_latitude",
        "end_station_longitude"
    FROM  "NEW_YORK_CITIBIKE_1"."NEW_YORK_CITIBIKE"."CITIBIKE_TRIPS"
    WHERE TO_DATE(TO_TIMESTAMP_LTZ("starttime"/1000000)) = '2015-07-15'
), trip_zips AS (      -- Attach start / end ZIPs via point-in-polygon
    SELECT
        zs."zip_code" AS start_zip,
        ze."zip_code" AS end_zip
    FROM trip_day t
    JOIN ny_zips  zs
      ON ST_WITHIN(
            TO_GEOGRAPHY(ST_MAKEPOINT(t."start_station_longitude", t."start_station_latitude")),
            zs.geom
         )
    JOIN ny_zips  ze
      ON ST_WITHIN(
            TO_GEOGRAPHY(ST_MAKEPOINT(t."end_station_longitude",   t."end_station_latitude")),
            ze.geom
         )
)
SELECT start_zip, end_zip
FROM (
    SELECT
        start_zip,
        end_zip,
        ROW_NUMBER() OVER (
            ORDER BY TO_NUMBER(start_zip) ASC,
                     TO_NUMBER(end_zip)   DESC
        ) AS rn
    FROM trip_zips        -- every trip already meets the “highest temp” criterion
) ranked
WHERE rn = 1;