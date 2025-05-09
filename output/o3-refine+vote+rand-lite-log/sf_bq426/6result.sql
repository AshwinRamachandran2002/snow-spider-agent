/* Highest‑average‑temperature user‑type for Citi Bike trips that both
   start and end inside Manhattan ZIP 10019 in 2018, together with the
   corresponding average weather metrics from the Central‑Park GSOD station */
WITH
-- polygon for ZIP‑code 10019
zip_geom AS (
    SELECT TO_GEOGRAPHY("zip_code_geom") AS geom
    FROM   "NEW_YORK_CITIBIKE_1"."GEO_US_BOUNDARIES"."ZIP_CODES"
    WHERE  "zip_code" = '10019'
),

-- Central‑Park weather‑station (keep most‑recent record)
central_park AS (
    SELECT "usaf", "wban"
    FROM   "NEW_YORK_CITIBIKE_1"."NOAA_GSOD"."STATIONS"
    WHERE  UPPER("name") LIKE '%CENTRAL PARK%'
      AND  "state" = 'NY'
    QUALIFY ROW_NUMBER() OVER (ORDER BY "end" DESC) = 1
),

-- daily weather at Central Park for 2018
weather AS (
    SELECT
        DATE_FROM_PARTS("year"::INT, "mo"::INT, "da"::INT) AS wx_date,
        "temp"                                             AS temp_f,
        "prcp"                                             AS prcp_in,
        "wdsp"::FLOAT                                      AS wind_knots
    FROM "NEW_YORK_CITIBIKE_1"."NOAA_GSOD"."GSOD2018" w
    JOIN central_park cp
      ON w."stn" = cp."usaf" AND w."wban" = cp."wban"
),

-- trips that both start and finish inside ZIP 10019 during 2018
trips_in_zip AS (
    SELECT
        "usertype",
        TO_DATE(TO_TIMESTAMP_NTZ("starttime" / 1e6)) AS trip_date
    FROM "NEW_YORK_CITIBIKE_1"."NEW_YORK_CITIBIKE"."CITIBIKE_TRIPS", zip_geom z
    WHERE YEAR(TO_TIMESTAMP_NTZ("starttime" / 1e6)) = 2018
      AND ST_WITHIN(
            TO_GEOGRAPHY('POINT(' || "start_station_longitude" || ' ' || "start_station_latitude" || ')'),
            z.geom
          )
      AND ST_WITHIN(
            TO_GEOGRAPHY('POINT(' || "end_station_longitude"   || ' ' || "end_station_latitude"   || ')'),
            z.geom
          )
)

-- aggregate weather per user type and return the warmest
SELECT
    t."usertype",
    AVG(w.temp_f)     AS avg_temperature_f,
    AVG(w.prcp_in)    AS avg_precip_in,
    AVG(w.wind_knots) AS avg_wind_speed_knots
FROM trips_in_zip t
JOIN weather w
  ON w.wx_date = t.trip_date
GROUP BY t."usertype"
ORDER BY avg_temperature_f DESC NULLS LAST
LIMIT 1;