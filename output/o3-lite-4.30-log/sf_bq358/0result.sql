WITH "DAILY_TRIPS" AS (
  SELECT
    zs."zip_code" AS "start_zip",
    ze."zip_code" AS "end_zip"
  FROM NEW_YORK_CITIBIKE_1.NEW_YORK_CITIBIKE.CITIBIKE_TRIPS t
  JOIN NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES.ZIP_CODES zs
    ON ST_WITHIN(
         TO_GEOGRAPHY('POINT(' || t."start_station_longitude" || ' ' || t."start_station_latitude" || ')'),
         TO_GEOGRAPHY(zs."zip_code_geom")
       )
  JOIN NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES.ZIP_CODES ze
    ON ST_WITHIN(
         TO_GEOGRAPHY('POINT(' || t."end_station_longitude" || ' ' || t."end_station_latitude" || ')'),
         TO_GEOGRAPHY(ze."zip_code_geom")
       )
  WHERE TO_DATE(TO_TIMESTAMP_NTZ(t."starttime" / 1000000)) = '2015-07-15'
    AND zs."state_code" = 'NY'
    AND ze."state_code" = 'NY'
)
SELECT
  "start_zip",
  "end_zip"
FROM (
  SELECT
    "start_zip",
    "end_zip",
    ROW_NUMBER() OVER (ORDER BY TO_NUMBER("start_zip") ASC, TO_NUMBER("end_zip") DESC) AS "rn"
  FROM "DAILY_TRIPS"
)
WHERE "rn" = 1;