WITH trips_on_day AS (                 /* CitiBike trips that began 2015‑07‑15 */
    SELECT  "start_station_latitude"  AS s_lat ,
            "start_station_longitude" AS s_lon ,
            "end_station_latitude"    AS e_lat ,
            "end_station_longitude"   AS e_lon
    FROM    NEW_YORK_CITIBIKE_1.NEW_YORK_CITIBIKE.CITIBIKE_TRIPS
    WHERE   DATE( TO_TIMESTAMP_NTZ("starttime" / 1000000) ) = '2015-07-15'
),
start_zipped AS (                      /* add ZIP for the start point          */
    SELECT  t.* ,
            z."zip_code" AS start_zip
    FROM    trips_on_day t
    JOIN    NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES.ZIP_CODES z
           ON ST_WITHIN(
                  ST_POINT(t.s_lon , t.s_lat) ,
                  TO_GEOGRAPHY(z."zip_code_geom")
              )
),
start_end_zipped AS (                  /* add ZIP for the end point            */
    SELECT  s.start_zip ,
            z."zip_code" AS end_zip
    FROM    start_zipped s
    JOIN    NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES.ZIP_CODES z
           ON ST_WITHIN(
                  ST_POINT(s.e_lon , s.e_lat) ,
                  TO_GEOGRAPHY(z."zip_code_geom")
              )
),
chosen_trip AS (                       /* smallest start ZIP, largest end ZIP  */
    SELECT  start_zip , end_zip
    FROM    start_end_zipped
    ORDER BY TO_NUMBER(start_zip) ASC ,
             TO_NUMBER(end_zip)   DESC
    LIMIT 1
)
SELECT  start_zip AS "START_ZIP",
        end_zip   AS "END_ZIP"
FROM    chosen_trip;