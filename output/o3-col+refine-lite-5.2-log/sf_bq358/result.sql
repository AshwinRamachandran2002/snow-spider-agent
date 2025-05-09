WITH
/* Central Park weather on 15‑Jul‑2015 (WBAN 94728) */
"cp_weather" AS (
    SELECT "temp"
    FROM   "NEW_YORK_CITIBIKE_1"."NOAA_GSOD"."GSOD2015"
    WHERE  "wban" = '94728'
      AND  "mo"   = '07'
      AND  "da"   = '15'
),
/* All Citi‑Bike trips that started on 15‑Jul‑2015 (NYC local time)  */
"day_trips" AS (
    SELECT *
    FROM   "NEW_YORK_CITIBIKE_1"."NEW_YORK_CITIBIKE"."CITIBIKE_TRIPS"
    WHERE  "starttime" BETWEEN 1436923200000000  -- 2015‑07‑15 00:00 EDT
                         AND     1437009599999999 -- 2015‑07‑15 23:59 EDT
),
/* Attach start‑ and end‑ZIP Codes to those trips                    */
"trips_with_zips" AS (
    SELECT
        zs."zip_code" AS "start_zip",
        ze."zip_code" AS "end_zip"
    FROM   "day_trips" t
    JOIN   "NEW_YORK_CITIBIKE_1"."GEO_US_BOUNDARIES"."ZIP_CODES" zs
           ON ST_WITHIN(
                  ST_MAKEPOINT(t."start_station_longitude",
                               t."start_station_latitude"),
                  ST_GEOGFROMWKB(zs."zip_code_geom"))
    JOIN   "NEW_YORK_CITIBIKE_1"."GEO_US_BOUNDARIES"."ZIP_CODES" ze
           ON ST_WITHIN(
                  ST_MAKEPOINT(t."end_station_longitude",
                               t."end_station_latitude"),
                  ST_GEOGFROMWKB(ze."zip_code_geom"))
)
/* Pick the trip that starts in the smallest ZIP and ends in the
   largest ZIP (ties broken by that ordering)                       */
SELECT  "start_zip",
        "end_zip"
FROM   (
        SELECT  *,
                ROW_NUMBER() OVER (ORDER BY "start_zip" ASC,
                                             "end_zip"  DESC) AS rn
        FROM    "trips_with_zips"
       )
WHERE  rn = 1;