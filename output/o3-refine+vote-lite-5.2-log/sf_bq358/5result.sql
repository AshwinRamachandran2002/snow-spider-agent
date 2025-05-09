WITH weather AS (   -- Central Park daily record for 15‑Jul‑2015
    SELECT "temp"
    FROM NEW_YORK_CITIBIKE_1.NOAA_GSOD.GSOD2015
    WHERE "wban" = '94728'
      AND "year" = '2015'
      AND "mo"   = '07'
      AND "da"   = '15'
), trips_20150715 AS (   -- Citi Bike trips that started on 15‑Jul‑2015 (local time)
    SELECT *
    FROM NEW_YORK_CITIBIKE_1.NEW_YORK_CITIBIKE.CITIBIKE_TRIPS
    WHERE DATE_TRUNC('day', TO_TIMESTAMP_LTZ("starttime" / 1000000)) = '2015-07-15'
), trips_with_zips AS (  -- attach start / end ZIPs via geospatial point‑in‑polygon tests
    SELECT
        z_start."zip_code" AS start_zip,
        z_end."zip_code"   AS end_zip
    FROM trips_20150715 t
    JOIN NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES.ZIP_CODES z_start
      ON ST_WITHIN(
           TO_GEOGRAPHY('POINT(' || t."start_station_longitude" || ' ' || t."start_station_latitude" || ')'),
           TO_GEOGRAPHY(z_start."zip_code_geom")
         )
    JOIN NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES.ZIP_CODES z_end
      ON ST_WITHIN(
           TO_GEOGRAPHY('POINT(' || t."end_station_longitude" || ' ' || t."end_station_latitude" || ')'),
           TO_GEOGRAPHY(z_end."zip_code_geom")
         )
)   -- pick the trip whose start‑ZIP is smallest and end‑ZIP is largest
SELECT start_zip, end_zip
FROM trips_with_zips
QUALIFY ROW_NUMBER()
          OVER (ORDER BY TO_NUMBER(start_zip) ASC,
                         TO_NUMBER(end_zip)  DESC) = 1;