/* ---------------------------------------------------------------------------
   Which user type recorded the highest average temperature on the days
   they rode (trips that both START and END inside NYC ZIP 10019 during 2018)?
   Return that user type together with the corresponding average temperature,
   precipitation, and wind-speed, all taken from the NOAA GSOD Central Park
   weather station (WBAN 94728).
--------------------------------------------------------------------------- */
WITH
/* 1.  Geometry for ZIP-code 10019 (Manhattan). */
zip_10019 AS (
    SELECT "zip_code_geom"
    FROM   NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES."ZIP_CODES"
    WHERE  "zip_code" = '10019'
),
/* 2.  Citi Bike station names that fall inside that ZIP. */
zip_stations AS (
    SELECT DISTINCT s."name"
    FROM   NEW_YORK_CITIBIKE_1.NEW_YORK_CITIBIKE."CITIBIKE_STATIONS" s,
           zip_10019 z
    WHERE  ST_WITHIN(
             TO_GEOGRAPHY(ST_MAKEPOINT(s."longitude", s."latitude")),
             TO_GEOGRAPHY(z."zip_code_geom")
           )
),
/* 3.  Central Park daily weather for 2018 (WBAN 94728). */
central_park_2018 AS (
    SELECT
        TO_DATE(
            CONCAT_WS(
                '-',
                g."year",
                LPAD(g."mo",2,'0'),
                LPAD(g."da",2,'0')
            )
        )                    AS "weather_date",
        g."temp"             AS "temp_f",
        g."prcp"             AS "prcp_in",
        g."wdsp"::FLOAT      AS "wdsp_knots"
    FROM NEW_YORK_CITIBIKE_1.NOAA_GSOD."GSOD2018" g
    WHERE g."wban" = '94728'
),
/* 4.  2018 trips that both start *and* end in ZIP 10019. */
zip_trips_2018 AS (
    SELECT
        t."usertype",
        TO_DATE(TO_TIMESTAMP(t."starttime" / 1000000)) AS "trip_date"
    FROM NEW_YORK_CITIBIKE_1.NEW_YORK_CITIBIKE."CITIBIKE_TRIPS" t
    WHERE TO_DATE(TO_TIMESTAMP(t."starttime" / 1000000))
              BETWEEN '2018-01-01' AND '2018-12-31'
      AND t."start_station_name" IN (SELECT "name" FROM zip_stations)
      AND t."end_station_name"   IN (SELECT "name" FROM zip_stations)
)
/* 5.  Join trips to same-day weather, then average per user type. */
SELECT
    zt."usertype",
    ROUND(AVG(w."temp_f"   ),4) AS "avg_temp_f",
    ROUND(AVG(w."prcp_in"  ),4) AS "avg_prcp_in",
    ROUND(AVG(w."wdsp_knots"),4) AS "avg_wdsp_knots"
FROM   zip_trips_2018     zt
JOIN   central_park_2018  w
  ON   w."weather_date" = zt."trip_date"
GROUP BY zt."usertype"
ORDER BY "avg_temp_f" DESC NULLS LAST
LIMIT 1;