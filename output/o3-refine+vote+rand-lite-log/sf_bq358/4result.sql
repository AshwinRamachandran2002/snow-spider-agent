/* 07‑15‑2015 bike‑trip whose start ZIP is the smallest and
   end ZIP the largest among all trips that both start and
   finish inside valid New York City ZIP Code polygons.           */

WITH trips_day AS (                     -- all Citi Bike trips on 2015‑07‑15
    SELECT *
    FROM  NEW_YORK_CITIBIKE_1.NEW_YORK_CITIBIKE.CITIBIKE_TRIPS
    WHERE DATE( CAST("starttime" / 1000000 AS TIMESTAMP_NTZ) ) = '2015-07-15'
),
trips_with_zips AS (                    -- attach start / end ZIP Codes
    SELECT
        sz."zip_code" AS start_zip,
        ez."zip_code" AS end_zip
    FROM  trips_day t
    JOIN  NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES.ZIP_CODES sz
          ON ST_CONTAINS(
                 TO_GEOGRAPHY(sz."zip_code_geom"),
                 TO_GEOGRAPHY('POINT('
                              || t."start_station_longitude" || ' '
                              || t."start_station_latitude"  || ')') )
    JOIN  NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES.ZIP_CODES ez
          ON ST_CONTAINS(
                 TO_GEOGRAPHY(ez."zip_code_geom"),
                 TO_GEOGRAPHY('POINT('
                              || t."end_station_longitude"   || ' '
                              || t."end_station_latitude"    || ')') )
)
SELECT  start_zip AS "START_ZIP",
        end_zip   AS "END_ZIP"
FROM    trips_with_zips
ORDER BY TO_NUMBER(start_zip) ASC,       -- pick smallest start‑ZIP
         TO_NUMBER(end_zip)   DESC       -- …and largest end‑ZIP
LIMIT   1;