/* 2014 Citi Bike neighbourhood‑to‑neighbourhood flows with Central Park weather */
WITH central_park AS (  ----------------------------------------------------------- 1
    /* Central Park GSOD station (USAF 725033 / WBAN 94728) */
    SELECT '725033' AS "usaf", '94728' AS "wban"
),
wx AS (                 ----------------------------------------------------------- 2
    /* Daily 2014 weather for Central Park */
    SELECT
        TO_DATE(CONCAT_WS('-', "year", "mo", "da"))                 AS "wx_date",
        "temp"                                                      AS "temp_f",
        CAST("wdsp" AS FLOAT) * 0.514444                            AS "wind_mps",   -- knots→m s‑1
        "prcp" * 2.54                                               AS "prcp_cm"     -- inch→cm
    FROM NEW_YORK_CITIBIKE_1.NOAA_GSOD.GSOD2014          g
    JOIN central_park                                        cp
      ON g."stn"  = cp."usaf"
     AND g."wban" = cp."wban"
),
trips_2014 AS (          ----------------------------------------------------------- 3
    /* 2014 trips with geographies & date parts */
    SELECT
        t.*,
        TO_TIMESTAMP("starttime"/1000000)::DATE                     AS "trip_date",
        MONTH(TO_TIMESTAMP("starttime"/1000000))                    AS "trip_month",
        TO_GEOGRAPHY(ST_MAKEPOINT("start_station_longitude",
                                  "start_station_latitude"))        AS "geo_start",
        TO_GEOGRAPHY(ST_MAKEPOINT("end_station_longitude",
                                  "end_station_latitude"))          AS "geo_end"
    FROM NEW_YORK_CITIBIKE_1.NEW_YORK_CITIBIKE.CITIBIKE_TRIPS t
    WHERE TO_TIMESTAMP("starttime"/1000000)::DATE
          BETWEEN '2014-01-01' AND '2014-12-31'
),
with_start_zip AS (      ----------------------------------------------------------- 4
    /* add start‑ZIP via point‑in‑polygon */
    SELECT
        tr.*,
        gz."zip_code"                                               AS "start_zip"
    FROM trips_2014                           tr
    JOIN NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES.ZIP_CODES gz
      ON ST_WITHIN(tr."geo_start",
                   TO_GEOGRAPHY(gz."zip_code_geom"))
),
with_both_zips AS (      ----------------------------------------------------------- 5
    /* add end‑ZIP */
    SELECT
        s.*,
        gz."zip_code"                                               AS "end_zip"
    FROM with_start_zip                        s
    JOIN NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES.ZIP_CODES gz
      ON ST_WITHIN(s."geo_end",
                   TO_GEOGRAPHY(gz."zip_code_geom"))
),
with_neigh AS (          ----------------------------------------------------------- 6
    /* map ZIPs → neighbourhoods */
    SELECT
        b.*,
        cs."neighborhood"                                           AS "start_neighborhood",
        ce."neighborhood"                                           AS "end_neighborhood"
    FROM with_both_zips                       b
    LEFT JOIN NEW_YORK_CITIBIKE_1.CYCLISTIC.ZIP_CODES cs
           ON cs."zip" = TO_NUMBER(b."start_zip")
    LEFT JOIN NEW_YORK_CITIBIKE_1.CYCLISTIC.ZIP_CODES ce
           ON ce."zip" = TO_NUMBER(b."end_zip")
    WHERE cs."neighborhood" IS NOT NULL
      AND ce."neighborhood" IS NOT NULL
),
with_weather AS (        ----------------------------------------------------------- 7
    /* append daily weather */
    SELECT
        n.*,
        w."temp_f",
        w."wind_mps",
        w."prcp_cm"
    FROM with_neigh n
    LEFT JOIN wx w
      ON w."wx_date" = n."trip_date"
),
agg AS (                 ----------------------------------------------------------- 8
    /* main aggregations */
    SELECT
        "start_neighborhood",
        "end_neighborhood",
        COUNT(*)                                   AS "total_trips",
        ROUND(AVG("tripduration")/60 , 1)          AS "avg_trip_duration_min",
        ROUND(AVG("temp_f")          , 1)          AS "avg_temperature_f",
        ROUND(AVG("wind_mps")        , 1)          AS "avg_wind_speed_mps",
        ROUND(AVG("prcp_cm")         , 1)          AS "avg_precipitation_cm"
    FROM with_weather
    GROUP BY 1,2
),
month_counts AS (       ----------------------------------------------------------- 9
    /* counts by month to find peak month */
    SELECT
        "start_neighborhood",
        "end_neighborhood",
        "trip_month",
        COUNT(*)                                   AS "m_trips"
    FROM with_weather
    GROUP BY 1,2,3
),
peak_month AS (         ---------------------------------------------------------- 10
    /* month with most trips (tie → smallest month number) */
    SELECT DISTINCT
        m."start_neighborhood",
        m."end_neighborhood",
        FIRST_VALUE(m."trip_month")
          OVER (PARTITION BY m."start_neighborhood", m."end_neighborhood"
                ORDER BY m."m_trips" DESC, m."trip_month")          AS "peak_month"
    FROM month_counts m
)
SELECT
    a."start_neighborhood",
    a."end_neighborhood",
    a."total_trips",
    a."avg_trip_duration_min",
    a."avg_temperature_f",
    a."avg_wind_speed_mps",
    a."avg_precipitation_cm",
    p."peak_month"
FROM agg        a
JOIN peak_month p
  ON a."start_neighborhood" = p."start_neighborhood"
 AND a."end_neighborhood"   = p."end_neighborhood"
ORDER BY a."total_trips" DESC NULLS LAST,
         a."start_neighborhood",
         a."end_neighborhood";