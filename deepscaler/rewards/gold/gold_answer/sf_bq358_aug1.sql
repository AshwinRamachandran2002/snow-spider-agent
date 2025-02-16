-- Task: Can you list the starting and ending ZIP codes for bike trips in New York City on July 15, 2015? Please limit the results to the first 100 trips.
SELECT
    "ZIPSTART"."zip_code" AS zip_code_start,
    "ZIPEND"."zip_code" AS zip_code_end
FROM  
    "NEW_YORK_CITIBIKE_1"."NEW_YORK_CITIBIKE"."CITIBIKE_TRIPS" AS "TRI"
INNER JOIN
    "NEW_YORK_CITIBIKE_1"."GEO_US_BOUNDARIES"."ZIP_CODES" AS "ZIPSTART"
    ON ST_WITHIN(
        ST_POINT("TRI"."start_station_longitude", "TRI"."start_station_latitude"),
        ST_GEOGFROMWKB("ZIPSTART"."zip_code_geom")
    )
INNER JOIN
    "NEW_YORK_CITIBIKE_1"."GEO_US_BOUNDARIES"."ZIP_CODES" AS "ZIPEND"
    ON ST_WITHIN(
        ST_POINT("TRI"."end_station_longitude", "TRI"."end_station_latitude"),
        ST_GEOGFROMWKB("ZIPEND"."zip_code_geom")
    )
WHERE
    DATE_TRUNC('DAY', TO_TIMESTAMP_NTZ(TO_NUMBER("TRI"."starttime") / 1000000)) = DATE '2015-07-15'
LIMIT 100;