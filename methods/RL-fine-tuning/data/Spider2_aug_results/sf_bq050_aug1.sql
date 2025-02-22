-- Task: Retrieve all bike trips in 2014 with their starting and ending neighborhoods, trip duration, temperature, wind speed, precipitation, and the month of the trip start. Limit the results to 100 rows.
WITH data AS (
    SELECT
        "ZIPSTARTNAME"."borough" AS "borough_start",
        "ZIPSTARTNAME"."neighborhood" AS "neighborhood_start",
        "ZIPENDNAME"."borough" AS "borough_end",
        "ZIPENDNAME"."neighborhood" AS "neighborhood_end",
        CAST("TRI"."tripduration" / 60 AS NUMERIC) AS "trip_minutes",
        "WEA"."temp" AS "temperature",
        CAST("WEA"."wdsp" AS NUMERIC) AS "wind_speed",
        "WEA"."prcp" AS "precipitation",
        EXTRACT(MONTH FROM DATE("TRI"."starttime")) AS "start_month"
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
    INNER JOIN
        "NEW_YORK_CITIBIKE_1"."NOAA_GSOD"."GSOD2014" AS "WEA"
        ON TO_DATE(CONCAT("WEA"."year", LPAD("WEA"."mo", 2, '0'), LPAD("WEA"."da", 2, '0')), 'YYYYMMDD') = DATE("TRI"."starttime")
    INNER JOIN
        "NEW_YORK_CITIBIKE_1"."CYCLISTIC"."ZIP_CODES" AS "ZIPSTARTNAME"
        ON "ZIPSTART"."zip_code" = CAST("ZIPSTARTNAME"."zip" AS STRING)
    INNER JOIN
        "NEW_YORK_CITIBIKE_1"."CYCLISTIC"."ZIP_CODES" AS "ZIPENDNAME"
        ON "ZIPEND"."zip_code" = CAST("ZIPENDNAME"."zip" AS STRING)
    WHERE
        "WEA"."wban" = (
            SELECT "wban" 
            FROM "NEW_YORK_CITIBIKE_1"."NOAA_GSOD"."STATIONS"
            WHERE
                "state" = 'NY'
                AND LOWER("name") LIKE LOWER('%New York Central Park%')
            LIMIT 1
        )
        AND EXTRACT(YEAR FROM DATE("TRI"."starttime")) = 2014
)
SELECT * FROM data
LIMIT 100;