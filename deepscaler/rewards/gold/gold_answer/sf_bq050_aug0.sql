-- Task: 
-- I want to analyze bike trips in New York City for the year 2014 by integrating trip data with weather information to understand how weather conditions (temperature, wind speed, and precipitation) influence bike trips between neighborhoods. For each combination of starting and ending neighborhoods—determined by mapping the trip start and end locations to ZIP codes based on geographic coordinates—I need the following:
-- 1. Total number of bike trips between the neighborhoods.
-- 2. Average trip duration in minutes (rounded to one decimal place).
-- 3. Average temperature at the start of the trip (rounded to one decimal place).
-- 4. Average wind speed at the start (in meters per second, rounded to one decimal place).
-- 5. Average precipitation at the start (in centimeters, rounded to one decimal place).
-- 6. The month with the highest number of trips between the neighborhoods (represented numerically, e.g., '4' for April).
-- 
-- The data should be grouped by the starting and ending neighborhoods, with:
-- - The `ZIP_CODES` table from `GEO_US_BOUNDARIES` used to map the bike trip start and end locations to ZIP codes by checking if the trip's start and end coordinates are within the ZIP code geometries.
-- - The `ZIP_CODES` table from `CYCLISTIC` used to obtain the borough and neighborhood names corresponding to the mapped ZIP codes.
-- - Weather data from the `GSOD2014` dataset in the `NOAA_GSOD` schema, using only data from the 'New York Central Park' weather station, matched to trips based on the trip start date.
-- 
-- Include only trips that occurred in 2014. Aggregate the data per combination of starting and ending neighborhoods, and determine the month with the most trips between each pair of neighborhoods.

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
),
agg_data AS (
    SELECT
        "borough_start",
        "neighborhood_start",
        "borough_end",
        "neighborhood_end",
        COUNT(*) AS "num_trips",
        ROUND(AVG("trip_minutes"), 1) AS "avg_trip_minutes",
        ROUND(AVG("temperature"), 1) AS "avg_temperature",
        ROUND(AVG("wind_speed"), 1) AS "avg_wind_speed",
        ROUND(AVG("precipitation"), 1) AS "avg_precipitation"
    FROM data
    GROUP BY
        "borough_start",
        "neighborhood_start",
        "borough_end",
        "neighborhood_end"
),
most_common_months AS (
    SELECT
        "borough_start",
        "neighborhood_start",
        "borough_end",
        "neighborhood_end",
        "start_month",
        ROW_NUMBER() OVER (
            PARTITION BY "borough_start", "neighborhood_start", "borough_end", "neighborhood_end" 
            ORDER BY COUNT(*) DESC
        ) AS "row_num"
    FROM data
    GROUP BY
        "borough_start",
        "neighborhood_start",
        "borough_end",
        "neighborhood_end",
        "start_month"
)

SELECT
    a.*,
    m."start_month" AS "most_common_month"
FROM
    agg_data a
JOIN
    most_common_months m
    ON a."borough_start" = m."borough_start" 
    AND a."neighborhood_start" = m."neighborhood_start" 
    AND a."borough_end" = m."borough_end" 
    AND a."neighborhood_end" = m."neighborhood_end" 
    AND m."row_num" = 1
ORDER BY 
    a."neighborhood_start", 
    a."neighborhood_end";