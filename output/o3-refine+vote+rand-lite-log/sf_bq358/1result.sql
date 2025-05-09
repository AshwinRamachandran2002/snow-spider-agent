WITH weather_cte AS (   -- Central Park (WBAN 94728) average temperature on 2015‑07‑15
    SELECT "temp" AS avg_temp
    FROM NEW_YORK_CITIBIKE_1.NOAA_GSOD.GSOD2015
    WHERE "year" = '2015'
      AND "mo"   = '07'
      AND "da"   = '15'
      AND "wban" = '94728'
), trip_zips AS (       -- trips on that day with both ends geocoded to ZIP areas
    SELECT
        sz."zip_code"  AS start_zip,
        ez."zip_code"  AS end_zip
    FROM NEW_YORK_CITIBIKE_1.NEW_YORK_CITIBIKE.CITIBIKE_TRIPS  t
    JOIN NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES.ZIP_CODES       sz
      ON ST_WITHIN(
             ST_MAKEPOINT(t."start_station_longitude",
                          t."start_station_latitude"),
             TO_GEOGRAPHY(sz."zip_code_geom")
         )
    JOIN NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES.ZIP_CODES       ez
      ON ST_WITHIN(
             ST_MAKEPOINT(t."end_station_longitude",
                          t."end_station_latitude"),
             TO_GEOGRAPHY(ez."zip_code_geom")
         )
    WHERE DATE_TRUNC('DAY', TO_TIMESTAMP_NTZ(t."starttime" / 1000000))
          = '2015-07-15'
)
SELECT
    start_zip  AS "START_ZIP",
    end_zip    AS "END_ZIP"
FROM trip_zips
ORDER BY start_zip ASC, end_zip DESC   -- smallest start ZIP, largest end ZIP
LIMIT 1;