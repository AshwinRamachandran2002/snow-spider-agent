/*-----------------------------------------------------------
  1)  New York City ZIP-code 10019 polygon
-----------------------------------------------------------*/
WITH zip10019 AS (
    SELECT TO_GEOGRAPHY("zip_code_geom") AS geom
    FROM   NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES.ZIP_CODES
    WHERE  "zip_code"  = '10019'
      AND  "state_code" = 'NY'
),
/*-----------------------------------------------------------
  2)  Identify a Central-Park weather station (USAF/WBAN)
-----------------------------------------------------------*/
central_park_id AS (            -- choose one row deterministically
    SELECT  "usaf",
            "wban"
    FROM    NEW_YORK_CITIBIKE_1.NOAA_GSOD.STATIONS
    WHERE   UPPER(TRIM("name"))  LIKE '%CENTRAL PARK%'
      AND   UPPER("state")       = 'NY'
    QUALIFY ROW_NUMBER() OVER (ORDER BY "end" DESC NULLS LAST) = 1
),
/*-----------------------------------------------------------
  3)  Central-Park daily weather for 2018
-----------------------------------------------------------*/
weather_2018 AS (
    SELECT  TO_DATE(CONCAT_WS('-', "year", "mo", "da"))          AS weather_date ,
            "prcp"                                               AS prcp_in ,
            TRY_TO_DOUBLE("wdsp")                                AS wind_kts ,
            "temp"                                               AS temp_f
    FROM    NEW_YORK_CITIBIKE_1.NOAA_GSOD.GSOD2018   w
    JOIN    central_park_id s
           ON w."stn"  = s."usaf"
          AND w."wban" = s."wban"
    WHERE   "prcp"              <> 99.99
      AND   "temp"              <> 9999.9
      AND   TRY_TO_DOUBLE("wdsp") <> 999.9
),
/*-----------------------------------------------------------
  4)  Citi-Bike trips that start AND end inside ZIP 10019 during 2018
-----------------------------------------------------------*/
trips_2018_10019 AS (
    SELECT  t."usertype",
            TO_DATE(
                CONVERT_TIMEZONE(
                    'UTC','America/New_York',
                    TO_TIMESTAMP(t."starttime" / 1e6)
                )
            )                                                    AS trip_date
    FROM    NEW_YORK_CITIBIKE_1.NEW_YORK_CITIBIKE.CITIBIKE_TRIPS      t
    JOIN    NEW_YORK_CITIBIKE_1.NEW_YORK_CITIBIKE.CITIBIKE_STATIONS   st
           ON t."start_station_name" = st."name"
    JOIN    NEW_YORK_CITIBIKE_1.NEW_YORK_CITIBIKE.CITIBIKE_STATIONS   en
           ON t."end_station_name"   = en."name"
    JOIN    zip10019 z
           ON ST_CONTAINS(z.geom ,
                TO_GEOGRAPHY('POINT('||st."longitude"||' '||st."latitude"||')'))
          AND ST_CONTAINS(z.geom ,
                TO_GEOGRAPHY('POINT('||en."longitude"||' '||en."latitude"||')'))
    WHERE   YEAR(
                CONVERT_TIMEZONE(
                    'UTC','America/New_York',
                    TO_TIMESTAMP(t."starttime" / 1e6)
                )
            ) = 2018
),
/*-----------------------------------------------------------
  5)  Attach weather to each trip (by calendar date)
-----------------------------------------------------------*/
trips_with_weather AS (
    SELECT  t."usertype",
            w.prcp_in,
            w.wind_kts,
            w.temp_f
    FROM    trips_2018_10019  t
    JOIN    weather_2018      w
          ON t.trip_date = w.weather_date
)
/*-----------------------------------------------------------
  6)  Compute averages per user-type and return the hottest
-----------------------------------------------------------*/
SELECT      "usertype"                           AS user_type ,
            AVG(temp_f)   AS avg_temperature_f ,
            AVG(prcp_in)  AS avg_precipitation_in ,
            AVG(wind_kts) AS avg_wind_speed_kts
FROM        trips_with_weather
GROUP BY    "usertype"
ORDER BY    avg_temperature_f DESC NULLS LAST
LIMIT 1;