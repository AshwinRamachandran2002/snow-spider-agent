WITH "nyc_trips" AS (
    SELECT
        sz."zip_code" AS "start_zip",
        ez."zip_code" AS "end_zip"
    FROM "NEW_YORK_CITIBIKE_1"."NEW_YORK_CITIBIKE"."CITIBIKE_TRIPS" t
    JOIN "NEW_YORK_CITIBIKE_1"."GEO_US_BOUNDARIES"."ZIP_CODES" sz
      ON ST_WITHIN(
           ST_POINT(t."start_station_longitude", t."start_station_latitude"),
           TO_GEOGRAPHY(sz."zip_code_geom")
         )
    JOIN "NEW_YORK_CITIBIKE_1"."GEO_US_BOUNDARIES"."ZIP_CODES" ez
      ON ST_WITHIN(
           ST_POINT(t."end_station_longitude", t."end_station_latitude"),
           TO_GEOGRAPHY(ez."zip_code_geom")
         )
    WHERE TO_DATE(TO_TIMESTAMP_NTZ(t."starttime" / 1000000)) = DATE '2015-07-15'
      AND sz."state_code" = 'NY'
      AND ez."state_code" = 'NY'
)
SELECT "start_zip", "end_zip"
FROM "nyc_trips"
ORDER BY TO_NUMBER("start_zip") ASC,
         TO_NUMBER("end_zip") DESC
LIMIT 1;