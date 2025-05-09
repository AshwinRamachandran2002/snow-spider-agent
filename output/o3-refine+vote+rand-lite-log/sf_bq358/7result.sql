WITH central_park_temp AS (   -- Central Park (WBAN 94728) reading for 2015‑07‑15
    SELECT "temp"
    FROM NEW_YORK_CITIBIKE_1.NOAA_GSOD.GSOD2015
    WHERE "wban" = '94728' 
      AND "year" = '2015' 
      AND "mo"   = '07' 
      AND "da"   = '15'
), 
trip_zip_codes AS (          -- 15 July 2015 trips with both ends mapped to NYC ZIP polygons
    SELECT
        z_start."zip_code"  AS start_zip,
        z_end."zip_code"    AS end_zip
    FROM NEW_YORK_CITIBIKE_1.NEW_YORK_CITIBIKE.CITIBIKE_TRIPS  t
    JOIN NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES.ZIP_CODES       z_start
      ON ST_WITHIN(
             TO_GEOGRAPHY(
               CONCAT('POINT(', t."start_station_longitude", ' ', t."start_station_latitude", ')')
             ),
             TO_GEOGRAPHY(z_start."zip_code_geom")
         )
    JOIN NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES.ZIP_CODES       z_end
      ON ST_WITHIN(
             TO_GEOGRAPHY(
               CONCAT('POINT(', t."end_station_longitude", ' ', t."end_station_latitude", ')')
             ),
             TO_GEOGRAPHY(z_end."zip_code_geom")
         )
    WHERE DATE( TO_TIMESTAMP_NTZ( t."starttime" / 1000000 ) ) = '2015-07-15'
), 
ranked_trips AS (            -- smallest start‑ZIP, then largest end‑ZIP
    SELECT
        start_zip,
        end_zip,
        RANK()  OVER (ORDER BY start_zip ASC)                       AS r_start,
        RANK()  OVER (PARTITION BY start_zip ORDER BY end_zip DESC) AS r_end
    FROM trip_zip_codes
)
SELECT 
    start_zip  AS "START_ZIP_CODE",
    end_zip    AS "END_ZIP_CODE"
FROM ranked_trips
WHERE r_start = 1      -- minimum start ZIP
  AND r_end   = 1      -- within that, maximum end ZIP
LIMIT 1;