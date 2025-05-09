WITH trips_zips AS (   --  All Citi Bike trips on 15-Jul-2015 with start- and end-ZIP codes
    SELECT
        t."tripduration",
        t."starttime",
        sz."zip_code" AS start_zip,
        ez."zip_code" AS end_zip
    FROM NEW_YORK_CITIBIKE_1.NEW_YORK_CITIBIKE.CITIBIKE_TRIPS   t
    JOIN NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES.ZIP_CODES        sz
      ON ST_INTERSECTS(
            TO_GEOGRAPHY(
                CONCAT('POINT(',t."start_station_longitude",' ',t."start_station_latitude",')')
            ),
            TO_GEOGRAPHY(sz."zip_code_geom")
         )
    JOIN NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES.ZIP_CODES        ez
      ON ST_INTERSECTS(
            TO_GEOGRAPHY(
                CONCAT('POINT(',t."end_station_longitude",' ',t."end_station_latitude",')')
            ),
            TO_GEOGRAPHY(ez."zip_code_geom")
         )
    WHERE DATE(TO_TIMESTAMP_LTZ(t."starttime" / 1000000)) = '2015-07-15'
)
SELECT
    start_zip ,
    end_zip
FROM trips_zips
ORDER BY
    CAST(start_zip AS INTEGER) ASC,
    CAST(end_zip   AS INTEGER) DESC
LIMIT 1;