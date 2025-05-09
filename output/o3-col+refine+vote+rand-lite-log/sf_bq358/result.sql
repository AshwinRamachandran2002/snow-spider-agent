/*  Bike-trip whose start-time falls on 15-Jul-2015, whose start and end
    points both lie inside ZIP-code polygons that (on that day) experienced
    the highest average temperature reported by Central Park station
    (WBAN 94728).  When several trips meet the criteria pick the one that
    starts in the smallest ZIP code and ends in the largest ZIP code.      */

WITH weather_day AS (   -- Central-Park report for 15-Jul-2015
  SELECT "temp"
  FROM   NEW_YORK_CITIBIKE_1.NOAA_GSOD.GSOD2015
  WHERE  "wban" = '94728'
    AND  "year" = '2015'
    AND  "mo"   = '07'
    AND  "da"   = '15'
), 

trips_20150715 AS (     -- Citi-Bike trips that began on that calendar day
  SELECT *,
         TO_GEOGRAPHY( ST_POINT("start_station_longitude",
                                "start_station_latitude") )  AS start_geom ,
         TO_GEOGRAPHY( ST_POINT("end_station_longitude",
                                "end_station_latitude") )    AS end_geom
  FROM   NEW_YORK_CITIBIKE_1.NEW_YORK_CITIBIKE.CITIBIKE_TRIPS
  WHERE  TO_TIMESTAMP_LTZ("starttime" / 1000000) 
            BETWEEN '2015-07-15'::TIMESTAMP 
                AND '2015-07-16'::TIMESTAMP
),

start_zipped AS (       -- attach start-ZIP
  SELECT t.*,
         z."zip_code"            AS start_zip
  FROM   trips_20150715 t
  JOIN   NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES.ZIP_CODES z
         ON  ST_WITHIN(t.start_geom , TO_GEOGRAPHY(z."zip_code_geom"))
),

fully_zipped AS (       -- attach end-ZIP
  SELECT s.*,
         z."zip_code"            AS end_zip
  FROM   start_zipped s
  JOIN   NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES.ZIP_CODES z
         ON  ST_WITHIN(s.end_geom , TO_GEOGRAPHY(z."zip_code_geom"))
),

ranked AS (             -- choose smallest start-ZIP / largest end-ZIP
  SELECT *,
         ROW_NUMBER() OVER (ORDER BY TO_NUMBER(start_zip) ASC,
                                      TO_NUMBER(end_zip)   DESC) AS rn
  FROM   fully_zipped
)

SELECT  start_zip  AS "START_ZIP",
        end_zip    AS "END_ZIP"
FROM    ranked
WHERE   rn = 1;