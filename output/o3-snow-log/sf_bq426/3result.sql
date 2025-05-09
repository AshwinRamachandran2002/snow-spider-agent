WITH zip_geom AS (   -- geometry of ZIP code 10019
    SELECT TO_GEOGRAPHY("zip_code_geom") AS geom
    FROM NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES.ZIP_CODES
    WHERE "zip_code" = '10019'
),

trips_2018 AS (      -- 2018 trips that both start AND end inside ZIP 10019
    SELECT 
        t."usertype",
        CAST( TO_TIMESTAMP_NTZ(t."starttime" / 1000000) AS DATE ) AS trip_date
    FROM NEW_YORK_CITIBIKE_1.NEW_YORK_CITIBIKE.CITIBIKE_TRIPS t
    CROSS JOIN zip_geom z
    WHERE YEAR( TO_TIMESTAMP_NTZ(t."starttime" / 1000000) ) = 2018
      AND ST_CONTAINS(
            z.geom ,
            TO_GEOGRAPHY(
                CONCAT('POINT(', t."start_station_longitude", ' ', t."start_station_latitude", ')')
            )
          )
      AND ST_CONTAINS(
            z.geom ,
            TO_GEOGRAPHY(
                CONCAT('POINT(', t."end_station_longitude",   ' ', t."end_station_latitude",   ')')
            )
          )
),

weather AS (         -- Central Park daily weather for 2018
    SELECT
        DATE_FROM_PARTS(TO_NUMBER("year"), TO_NUMBER("mo"), TO_NUMBER("da"))  AS weather_date,
        "temp"::FLOAT  AS temp_f,
        "prcp"::FLOAT  AS prcp_in,
        "wdsp"::FLOAT  AS wind_knots
    FROM NEW_YORK_CITIBIKE_1.NOAA_GSOD.GSOD2018  w
    JOIN NEW_YORK_CITIBIKE_1.NOAA_GSOD.STATIONS  s
          ON  s."usaf" = w."stn"
          AND s."wban" = w."wban"
    WHERE UPPER(TRIM(s."name")) LIKE '%CENTRAL PARK%'
)

, joined AS (        -- merge trips with same-day weather
    SELECT
        t."usertype",
        w.temp_f,
        w.prcp_in,
        w.wind_knots
    FROM trips_2018 t
    JOIN weather   w
      ON t.trip_date = w.weather_date
)

SELECT
    "usertype",
    AVG(temp_f)     AS avg_temperature_f,
    AVG(prcp_in)    AS avg_precipitation_in,
    AVG(wind_knots) AS avg_wind_speed_knots
FROM joined
GROUP BY "usertype"
ORDER BY avg_temperature_f DESC NULLS LAST
LIMIT 1;