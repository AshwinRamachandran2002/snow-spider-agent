/*  Bike–weather analysis for NYC 2014
    – neighbourhood-to-neighbourhood summary                     */

WITH cp_weather AS (   -- Central Park daily weather (WBAN 94728)
    SELECT
        TO_DATE(TO_CHAR("year")||'-'||LPAD("mo",2,'0')||'-'||LPAD("da",2,'0'))                         AS "wx_date",
        ROUND("temp",             1)                                                                  AS "temp_f",
        ROUND(CAST("wdsp" AS FLOAT)*0.514444 ,1)                                                      AS "wind_mps",      -- knots → m s-1
        ROUND("prcp"*2.54        ,1)                                                                  AS "prcp_cm"        -- inch  → cm
    FROM NEW_YORK_CITIBIKE_1.NOAA_GSOD."GSOD2014"
    WHERE "wban" = '94728'              -- Central Park station
),

trip_2014 AS (          -- 2014 Citi-Bike rides with useful columns
    SELECT
        CT."tripduration"/60.0                                                           AS "trip_min",
        TO_TIMESTAMP_NTZ(CT."starttime"/1000000)                                         AS "start_ts",
        TO_DATE(TO_TIMESTAMP_NTZ(CT."starttime"/1000000))                                AS "trip_date",
        MONTH(TO_TIMESTAMP_NTZ(CT."starttime"/1000000))                                  AS "trip_month",
        CT."start_station_latitude"                                                      AS "start_lat",
        CT."start_station_longitude"                                                     AS "start_lon",
        CT."end_station_latitude"                                                        AS "end_lat",
        CT."end_station_longitude"                                                       AS "end_lon"
    FROM NEW_YORK_CITIBIKE_1.NEW_YORK_CITIBIKE."CITIBIKE_TRIPS" CT
    WHERE YEAR(TO_TIMESTAMP_NTZ(CT."starttime"/1000000)) = 2014
),

/* ------------------------------------------------------------ */
/*  Spatial join – trip start point ➔ ZIP polygon ➔ neighbourhood */
start_zip AS (
    SELECT
        T.*,
        CZS."borough"      AS "start_borough",
        CZS."neighborhood" AS "start_neighborhood"
    FROM trip_2014 T
    JOIN NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES."ZIP_CODES" GZ
      ON ST_CONTAINS(
           TO_GEOGRAPHY(GZ."zip_code_geom"),
           TO_GEOGRAPHY('POINT('||T."start_lon"||' '||T."start_lat"||')')
         )
    JOIN NEW_YORK_CITIBIKE_1.CYCLISTIC."ZIP_CODES" CZS
      ON GZ."zip_code" = CZS."zip"::TEXT
),

/*  Spatial join – trip end point ➔ ZIP polygon ➔ neighbourhood  */
full_trip AS (
    SELECT
        SZ.*,
        CZE."borough"      AS "end_borough",
        CZE."neighborhood" AS "end_neighborhood"
    FROM start_zip SZ
    JOIN NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES."ZIP_CODES" GZE
      ON ST_CONTAINS(
           TO_GEOGRAPHY(GZE."zip_code_geom"),
           TO_GEOGRAPHY('POINT('||SZ."end_lon"||' '||SZ."end_lat"||')')
         )
    JOIN NEW_YORK_CITIBIKE_1.CYCLISTIC."ZIP_CODES" CZE
      ON GZE."zip_code" = CZE."zip"::TEXT
),

/*  Attach Central-Park weather for the ride date                */
trip_weather AS (
    SELECT
        F.*,
        W."temp_f",
        W."wind_mps",
        W."prcp_cm"
    FROM full_trip F
    JOIN cp_weather W
      ON F."trip_date" = W."wx_date"
),

/*  Basic aggregations                                            */
agg_base AS (
    SELECT
        "start_borough",
        "start_neighborhood",
        "end_borough",
        "end_neighborhood",
        COUNT(*)                         AS "total_trips",
        ROUND(AVG("trip_min") ,1)        AS "avg_trip_min",
        ROUND(AVG("temp_f")   ,1)        AS "avg_temp_f",
        ROUND(AVG("wind_mps") ,1)        AS "avg_wind_mps",
        ROUND(AVG("prcp_cm")  ,1)        AS "avg_prcp_cm"
    FROM trip_weather
    GROUP BY
        "start_borough","start_neighborhood",
        "end_borough"  ,"end_neighborhood"
),

/*  Determine peak-trip month for each neighbourhood pair         */
month_counts AS (
    SELECT
        "start_neighborhood",
        "end_neighborhood",
        "trip_month",
        COUNT(*)                                                AS "month_trips",
        ROW_NUMBER() OVER (PARTITION BY "start_neighborhood","end_neighborhood"
                           ORDER BY COUNT(*) DESC, "trip_month") AS "rn"
    FROM trip_weather
    GROUP BY "start_neighborhood","end_neighborhood","trip_month"
)

/* -----------------------  FINAL RESULT  ----------------------- */
SELECT
    A."start_borough",
    A."start_neighborhood",
    A."end_borough",
    A."end_neighborhood",
    A."total_trips",
    A."avg_trip_min",
    A."avg_temp_f",
    A."avg_wind_mps",
    A."avg_prcp_cm",
    MC."trip_month"                     AS "peak_month"
FROM      agg_base     A
JOIN      month_counts MC
       ON A."start_neighborhood" = MC."start_neighborhood"
      AND A."end_neighborhood"   = MC."end_neighborhood"
      AND MC."rn" = 1
ORDER BY A."total_trips" DESC NULLS LAST;