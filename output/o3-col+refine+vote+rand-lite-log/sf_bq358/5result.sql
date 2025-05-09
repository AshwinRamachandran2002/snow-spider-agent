/* Identify every Citi Bike trip on 15-Jul-2015 whose start and end
 locations both fall inside any New York-State ZIP polygon.
 Return the single trip that has the smallest starting ZIP code and
 (the tie-breaker) the largest ending ZIP code.                */

WITH day_trips AS (               -- all trips on 15-Jul-2015
    SELECT  "bikeid",
            "start_station_longitude" AS start_lon,
            "start_station_latitude"  AS start_lat,
            "end_station_longitude"   AS end_lon,
            "end_station_latitude"    AS end_lat
    FROM    NEW_YORK_CITIBIKE_1.NEW_YORK_CITIBIKE.CITIBIKE_TRIPS
    WHERE   TO_DATE( TO_TIMESTAMP_LTZ("starttime" / 1000000) ) = '2015-07-15'
),
start_zips AS (                   -- map trip-starts to NY ZIPs
    SELECT  t."bikeid",
            z."zip_code" AS start_zip
    FROM    day_trips t
    JOIN    NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES.ZIP_CODES z
          ON ST_COVEREDBY(
                 ST_POINT(t.start_lon , t.start_lat) ,
                 TO_GEOGRAPHY(z."zip_code_geom")
             )
    WHERE   z."state_code" = 'NY'
),
end_zips AS (                     -- map trip-ends to NY ZIPs
    SELECT  t."bikeid",
            z."zip_code" AS end_zip
    FROM    day_trips t
    JOIN    NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES.ZIP_CODES z
          ON ST_COVEREDBY(
                 ST_POINT(t.end_lon , t.end_lat) ,
                 TO_GEOGRAPHY(z."zip_code_geom")
             )
    WHERE   z."state_code" = 'NY'
)
SELECT  s.start_zip ,
        e.end_zip
FROM    start_zips  s
JOIN    end_zips    e USING ("bikeid")
ORDER BY s.start_zip ASC,
         e.end_zip   DESC
LIMIT 1;