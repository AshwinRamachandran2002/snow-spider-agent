/*-----------------------------------------------------------
  1.  Obtain 15-Jul-2015 GSOD temperatures, map every NY-state
      station to its ZIP, and compute average-temp per ZIP.
  2.  Keep only those ZIPs that actually contain at least one
      Citi Bike trip (start or end) on the same day.
  3.  From that subset, find the ZIP(s) whose average-temp is
      the maximum (“hottest ZIPs”).
  4.  Select trips on 15-Jul-2015 whose start- and end-points
      both fall in any hottest ZIP.
  5.  Return the trip that starts in the smallest-area ZIP and
      ends in the largest-area ZIP, reporting those two ZIPs.
-----------------------------------------------------------*/
WITH gsod_15_jul AS (                        -- GSOD rows for 15-Jul-2015
    SELECT  g."stn",
            g."wban",
            g."temp"
    FROM  NEW_YORK_CITIBIKE_1.NOAA_GSOD.GSOD2015 g
    WHERE g."year"='2015' AND g."mo"='07' AND g."da"='15'
      AND g."temp" <> 9999.9
), station_pts AS (                          -- station coordinates
    SELECT  s."usaf" AS "stn",
            s."wban",
            CAST(s."lat" AS DOUBLE) AS lat,
            CAST(s."lon" AS DOUBLE) AS lon
    FROM NEW_YORK_CITIBIKE_1.NOAA_GSOD.STATIONS s
    WHERE s."lat"<>0 AND s."lon"<>0
), station_zip AS (                          -- map station → ZIP
    SELECT
        g."temp",
        z."zip_code",
        z."zip_code_geom",
        z."area_land_meters"
    FROM   gsod_15_jul g
    JOIN   station_pts p
           ON g."stn"=p."stn" AND g."wban"=p."wban"
    JOIN   NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES.ZIP_CODES z
           ON z."state_code"='NY'
          AND ST_WITHIN(
                 ST_MAKEPOINT(p.lon , p.lat),
                 TO_GEOGRAPHY(z."zip_code_geom")
              )
), zip_avg_temp AS (                         -- ave temp per ZIP
    SELECT
        "zip_code",
        MIN("zip_code_geom")    AS zip_geom,
        MIN("area_land_meters") AS land_area,
        AVG("temp")             AS avg_temp
    FROM station_zip
    GROUP BY "zip_code"
), trips_15_jul AS (                         -- Citi Bike trips that day
    SELECT
        ST_MAKEPOINT("start_station_longitude","start_station_latitude") AS start_geom,
        ST_MAKEPOINT("end_station_longitude"  ,"end_station_latitude")   AS end_geom
    FROM NEW_YORK_CITIBIKE_1.NEW_YORK_CITIBIKE.CITIBIKE_TRIPS
    WHERE TO_DATE(TO_TIMESTAMP_NTZ("starttime"/1000000))='2015-07-15'
), zips_with_trips AS (                      -- ZIPs touched by any trip
    SELECT DISTINCT z."zip_code"
    FROM trips_15_jul t
    JOIN NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES.ZIP_CODES z
          ON z."state_code"='NY'
         AND ( ST_WITHIN(t.start_geom,TO_GEOGRAPHY(z."zip_code_geom"))
            OR ST_WITHIN(t.end_geom  ,TO_GEOGRAPHY(z."zip_code_geom")) )
), candidate_zips AS (                       -- restrict temps to those ZIPs
    SELECT *
    FROM   zip_avg_temp
    WHERE  "zip_code" IN (SELECT "zip_code" FROM zips_with_trips)
), hottest AS (                              -- hottest among candidate ZIPs
    SELECT *
    FROM   candidate_zips
    QUALIFY avg_temp = MAX(avg_temp) OVER ()
), eligible_trips AS (                       -- trips whose endpoints in hottest ZIPs
    SELECT
        z_start."zip_code"  AS start_zip,
        z_end.  "zip_code"  AS end_zip,
        z_start.land_area   AS start_area,
        z_end.  land_area   AS end_area
    FROM trips_15_jul t
    JOIN hottest z_start
         ON ST_WITHIN(t.start_geom, TO_GEOGRAPHY(z_start.zip_geom))
    JOIN hottest z_end
         ON ST_WITHIN(t.end_geom  , TO_GEOGRAPHY(z_end.zip_geom))
)
SELECT
    start_zip AS "starting_zip_code",
    end_zip   AS "ending_zip_code"
FROM   eligible_trips
ORDER BY start_area ASC NULLS LAST,
         end_area   DESC NULLS LAST
LIMIT 1;