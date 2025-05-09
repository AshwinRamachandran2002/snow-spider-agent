WITH zip_geom AS (                                                    -- 10019 boundary
    SELECT TO_GEOGRAPHY("zip_code_geom", 4326) AS geom
    FROM   NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES."ZIP_CODES"
    WHERE  "zip_code" = '10019'
),
stations_in_zip AS (                                                  -- stations inside 10019
    SELECT DISTINCT
           s."name"
    FROM   NEW_YORK_CITIBIKE_1.NEW_YORK_CITIBIKE."CITIBIKE_STATIONS" s,
           zip_geom z
    WHERE  ST_WITHIN(
              ST_MAKEPOINT(s."longitude", s."latitude"),
              z.geom
           )
),
trips_2018 AS (                                                       -- 2018 trips that both
    SELECT                                                            -- start AND end in 10019
           t."usertype",
           TO_DATE(TO_TIMESTAMP_LTZ(t."starttime" / 1000000)) AS "ride_date"
    FROM   NEW_YORK_CITIBIKE_1.NEW_YORK_CITIBIKE."CITIBIKE_TRIPS" t
    WHERE  YEAR(TO_TIMESTAMP_LTZ(t."starttime" / 1000000)) = 2018
      AND  t."start_station_name" IN (SELECT "name" FROM stations_in_zip)
      AND  t."end_station_name"   IN (SELECT "name" FROM stations_in_zip)
),
weather AS (                                                           -- Central Park daily WX
    SELECT
           TO_DATE("year" || '-' || "mo" || '-' || "da")       AS "wx_date",
           "temp",
           "prcp",
           TRY_TO_NUMBER("wdsp")                                AS "wdsp"
    FROM   NEW_YORK_CITIBIKE_1.NOAA_GSOD."GSOD2018"
    WHERE  "wban" = '94728'   -- New York Central Park station
)
SELECT
       t."usertype",
       AVG(w."temp")  AS "avg_temp_F",
       AVG(w."prcp")  AS "avg_prcp_in",
       AVG(w."wdsp")  AS "avg_wdsp_knots"
FROM   trips_2018 t
JOIN   weather   w
  ON   t."ride_date" = w."wx_date"
GROUP BY t."usertype"
ORDER BY "avg_temp_F" DESC NULLS LAST
LIMIT 1;