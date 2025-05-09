WITH zip_geom AS (
    SELECT TO_GEOGRAPHY("zip_code_geom") AS geom
    FROM NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES."ZIP_CODES"
    WHERE "zip_code" = '10019'
),
trips AS (
    SELECT
        t."usertype",
        TO_DATE(TO_TIMESTAMP_NTZ(t."starttime" / 1e6)) AS trip_day
    FROM NEW_YORK_CITIBIKE_1.NEW_YORK_CITIBIKE."CITIBIKE_TRIPS" t,
         zip_geom z
    WHERE YEAR(TO_TIMESTAMP_NTZ(t."starttime" / 1e6)) = 2018
      AND ST_WITHIN(
            TO_GEOGRAPHY(CONCAT('POINT(', t."start_station_longitude", ' ', t."start_station_latitude", ')')),
            z.geom
          )
      AND ST_WITHIN(
            TO_GEOGRAPHY(CONCAT('POINT(', t."end_station_longitude", ' ', t."end_station_latitude", ')')),
            z.geom
          )
),
weather AS (
    SELECT
        TO_DATE("year" || '-' || "mo" || '-' || "da")  AS trip_day,
        "temp"                                         AS temp_f,
        "prcp"                                         AS prcp_in,
        CAST("wdsp" AS FLOAT)                          AS wdsp_knots
    FROM NEW_YORK_CITIBIKE_1.NOAA_GSOD."GSOD2018"
    WHERE "wban" = '94728'   -- New York Central Park station
)
SELECT
    t."usertype",
    AVG(w.temp_f)     AS avg_temp_f,
    AVG(w.prcp_in)    AS avg_prcp_in,
    AVG(w.wdsp_knots) AS avg_wdsp_knots
FROM trips t
JOIN weather w USING (trip_day)
GROUP BY t."usertype"
ORDER BY avg_temp_f DESC NULLS LAST
LIMIT 1;