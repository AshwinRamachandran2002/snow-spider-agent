/* -----------------------------------------------------------------
   Bike‑trip on 15‑Jul‑2015 whose START and END zip codes belong to
   the five ZIP polygons geographically closest to the Central Park
   weather station (WBAN 94728).  If several trips qualify, return
   the one with the lexicographically‑smallest START_ZIP and the
   largest END_ZIP.
   -----------------------------------------------------------------*/
WITH cp_station AS (                      -- Central Park point
    SELECT "lat", "lon"
    FROM NEW_YORK_CITIBIKE_1.NOAA_GSOD.STATIONS
    WHERE "wban" = '94728'
    QUALIFY ROW_NUMBER() OVER (ORDER BY "end" DESC NULLS LAST)=1
),
nearest_zips AS (                         -- 5 ZIPs nearest to that point
    SELECT  z."zip_code",
            ROW_NUMBER() OVER (
                ORDER BY ST_DISTANCE(
                             TO_GEOGRAPHY(z."zip_code_geom"),
                             TO_GEOGRAPHY(ST_POINT(s."lon",s."lat"))
                         )
            )  AS rnk
    FROM NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES."ZIP_CODES" z
    CROSS JOIN cp_station s
),
cp_zips AS (SELECT "zip_code"
            FROM   nearest_zips
            WHERE  rnk <= 5),             -- keep the closest five
trip_day AS (                             -- Citi Bike trips on 2015‑07‑15
    SELECT *
    FROM NEW_YORK_CITIBIKE_1.NEW_YORK_CITIBIKE.CITIBIKE_TRIPS
    WHERE DATE(TO_TIMESTAMP_NTZ("starttime"/1e6)) = '2015-07-15'
),
start_zip AS (                            -- attach start ZIP via INTERSECTS
    SELECT  t.*,
            z."zip_code" AS start_zip
    FROM    trip_day t
    JOIN    NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES."ZIP_CODES" z
      ON ST_INTERSECTS(
             TO_GEOGRAPHY(z."zip_code_geom"),
             TO_GEOGRAPHY(ST_POINT(t."start_station_longitude",
                                   t."start_station_latitude"))
         )
),
both_zips AS (                            -- attach end ZIP
    SELECT  s.start_zip,
            z2."zip_code" AS end_zip
    FROM    start_zip s
    JOIN    NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES."ZIP_CODES" z2
      ON ST_INTERSECTS(
             TO_GEOGRAPHY(z2."zip_code_geom"),
             TO_GEOGRAPHY(ST_POINT(s."end_station_longitude",
                                   s."end_station_latitude"))
         )
    WHERE s.start_zip IN (SELECT "zip_code" FROM cp_zips)
      AND z2."zip_code" IN (SELECT "zip_code" FROM cp_zips)
)
SELECT  start_zip AS "START_ZIP",
        end_zip   AS "END_ZIP"
FROM    both_zips
QUALIFY ROW_NUMBER() OVER (ORDER BY start_zip ASC, end_zip DESC) = 1;