/*  Citi Bike 2014 – neighborhood-to-neighborhood flows with Central Park weather */

WITH trips_2014 AS (   -- raw trips in calendar-year 2014
    SELECT
        t."tripduration"                         AS tripduration,     -- alias w/out quotes
        CAST(t."starttime" / 1e6 AS TIMESTAMP)   AS start_ts,
        DATE(CAST(t."starttime" / 1e6 AS TIMESTAMP))  AS trip_date,
        ST_MAKEPOINT(t."start_station_longitude", t."start_station_latitude") AS start_geog,
        ST_MAKEPOINT(t."end_station_longitude"  , t."end_station_latitude"  ) AS end_geog
    FROM NEW_YORK_CITIBIKE_1.NEW_YORK_CITIBIKE."CITIBIKE_TRIPS" t
    WHERE t."starttime" BETWEEN 1388534400000000 AND 1420070399000000
      AND t."start_station_longitude" IS NOT NULL
      AND t."end_station_longitude"   IS NOT NULL
),

trips_with_neighborhoods AS (   -- map start / end points to Cyclistic neighborhoods
    SELECT
        tripduration,
        start_ts,
        trip_date,
        cz_start."neighborhood" AS start_nbhd,
        cz_end."neighborhood"   AS end_nbhd
    FROM trips_2014 t
    JOIN NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES."ZIP_CODES" gz_start
         ON ST_WITHIN(
                t.start_geog ,
                ST_GEOGFROMWKB(gz_start."zip_code_geom")
            )
    JOIN NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES."ZIP_CODES" gz_end
         ON ST_WITHIN(
                t.end_geog ,
                ST_GEOGFROMWKB(gz_end."zip_code_geom")
            )
    JOIN NEW_YORK_CITIBIKE_1.CYCLISTIC."ZIP_CODES" cz_start
         ON cz_start."zip" = gz_start."zip_code"
    JOIN NEW_YORK_CITIBIKE_1.CYCLISTIC."ZIP_CODES" cz_end
         ON cz_end."zip" = gz_end."zip_code"
),

weather_central_park AS (   -- Central Park GSOD daily weather (station 725033-94728)
    SELECT
        TO_DATE(CONCAT("year",'-',LPAD("mo",2,'0'),'-',LPAD("da",2,'0'))) AS weather_date,
        "temp"                                    AS temp_f,
        CAST("wdsp" AS FLOAT) * 0.514444          AS wind_mps,   -- knots → m s-¹
        "prcp" * 2.54                             AS prcp_cm     -- inches → cm
    FROM NEW_YORK_CITIBIKE_1.NOAA_GSOD."GSOD2014"
    WHERE "stn"  = '725033'
      AND "wban" = '94728'
      AND "temp" <> 9999.9
),

trips_weather AS (   -- attach same-day weather to each trip
    SELECT
        n.*,
        w.temp_f,
        w.wind_mps,
        w.prcp_cm
    FROM trips_with_neighborhoods n
    LEFT JOIN weather_central_park w
           ON w.weather_date = n.trip_date
),

overall_pair AS (    -- required aggregates
    SELECT
        start_nbhd,
        end_nbhd,
        COUNT(*)                       AS total_trips,
        ROUND(AVG(tripduration)/60,1)  AS avg_duration_min,
        ROUND(AVG(temp_f),  1)         AS avg_temperature_f,
        ROUND(AVG(wind_mps),1)         AS avg_wind_speed_mps,
        ROUND(AVG(prcp_cm), 1)         AS avg_precipitation_cm
    FROM trips_weather
    GROUP BY start_nbhd, end_nbhd
),

monthly_counts AS (   -- trip counts per pair & month
    SELECT
        start_nbhd,
        end_nbhd,
        MONTH(start_ts) AS trip_month,
        COUNT(*)        AS month_trips
    FROM trips_weather
    GROUP BY start_nbhd, end_nbhd, MONTH(start_ts)
),

peak_month AS (       -- month with most trips for each pair
    SELECT
        start_nbhd,
        end_nbhd,
        trip_month AS peak_month
    FROM (
        SELECT
            start_nbhd,
            end_nbhd,
            trip_month,
            month_trips,
            ROW_NUMBER() OVER (PARTITION BY start_nbhd, end_nbhd
                               ORDER BY month_trips DESC) AS rn
        FROM monthly_counts
    )
    WHERE rn = 1
)

SELECT
    o.start_nbhd            AS "start_neighborhood",
    o.end_nbhd              AS "end_neighborhood",
    o.total_trips,
    o.avg_duration_min,
    o.avg_temperature_f,
    o.avg_wind_speed_mps,
    o.avg_precipitation_cm,
    p.peak_month
FROM overall_pair o
JOIN peak_month p
  ON p.start_nbhd = o.start_nbhd
 AND p.end_nbhd   = o.end_nbhd
ORDER BY o.total_trips DESC NULLS LAST;