WITH target_zip AS (   -- geometry of NYC ZIP 10019
    SELECT TO_GEOGRAPHY("zip_code_geom") AS geom
    FROM NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES.ZIP_CODES
    WHERE "zip_code" = '10019'
    LIMIT 1
),

trips_2018 AS (        -- 2018 trips that both start AND end inside ZIP 10019
    SELECT
        "usertype",
        TO_DATE(TO_TIMESTAMP_NTZ("starttime" / 1000000)) AS trip_date
    FROM NEW_YORK_CITIBIKE_1.NEW_YORK_CITIBIKE.CITIBIKE_TRIPS t
    CROSS JOIN target_zip z
    WHERE DATE_PART('year', TO_TIMESTAMP_NTZ("starttime" / 1000000)) = 2018
      AND ST_WITHIN(ST_MAKEPOINT("start_station_longitude","start_station_latitude"), z.geom)
      AND ST_WITHIN(ST_MAKEPOINT("end_station_longitude"  ,"end_station_latitude")  , z.geom)
),

cp_station AS (        -- most‑recent Central Park GSOD station
    SELECT "usaf" AS stn,
           "wban" AS wban
    FROM NEW_YORK_CITIBIKE_1.NOAA_GSOD.STATIONS
    WHERE UPPER(TRIM("name")) LIKE '%CENTRAL PARK%'
      AND "state" = 'NY'
    QUALIFY ROW_NUMBER() OVER (ORDER BY "end" DESC) = 1
),

weather_cp AS (        -- Central Park daily weather for 2018
    SELECT
        TO_DATE("year" || '-' || LPAD("mo",2,'0') || '-' || LPAD("da",2,'0'))                     AS wdate,
        NULLIF("temp", 9999.9)::FLOAT                                                            AS temp_f,
        CASE WHEN "prcp" = 99.99  THEN NULL ELSE "prcp"::FLOAT END                               AS prcp_in,
        CASE WHEN "wdsp" IN ('999.9','9999.9') THEN NULL ELSE "wdsp"::FLOAT END                  AS wdsp_kts
    FROM NEW_YORK_CITIBIKE_1.NOAA_GSOD.GSOD2018 d
    JOIN cp_station s
      ON d."stn"  = s.STN
     AND d."wban" = s.WBAN
)

SELECT
    t."usertype"                                           AS "USER_TYPE",
    ROUND(AVG(w.temp_f),  2)                               AS "AVG_TEMP_F",
    ROUND(AVG(w.prcp_in), 2)                               AS "AVG_PRCP_IN",
    ROUND(AVG(w.wdsp_kts),2)                               AS "AVG_WIND_SPEED_KTS"
FROM trips_2018 t
JOIN weather_cp w
  ON t.trip_date = w.wdate
GROUP BY t."usertype"
ORDER BY "AVG_TEMP_F" DESC NULLS LAST
LIMIT 1;