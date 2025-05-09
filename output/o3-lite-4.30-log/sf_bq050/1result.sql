/* Bike‑trips 2014  ⇢  ZIP polygons  ⇢  neighborhoods  ⇢  Central‑Park weather */
WITH trips_2014 AS (      -- keep only 2014 rides
    SELECT
        DATE(TO_TIMESTAMP_LTZ("starttime" / 1000000))                 AS trip_date,
        "tripduration" / 60.0                                         AS duration_min,
        "start_station_latitude",
        "start_station_longitude",
        "end_station_latitude",
        "end_station_longitude"
    FROM NEW_YORK_CITIBIKE_1.NEW_YORK_CITIBIKE.CITIBIKE_TRIPS
    WHERE DATE(TO_TIMESTAMP_LTZ("starttime" / 1000000))
          BETWEEN '2014-01-01' AND '2014-12-31'
),
/* -------- daily Central Park weather ---------------------------------------- */
weather AS (
    SELECT
        TO_DATE("year" || '-' || LPAD("mo",2,'0') || '-' || LPAD("da",2,'0'))      AS weather_date,
        CASE WHEN "temp"  >= 9999 THEN NULL ELSE "temp"           END              AS temp_f,
        CASE WHEN TRY_TO_DOUBLE("wdsp") IS NULL OR TRY_TO_DOUBLE("wdsp") >= 999
             THEN NULL ELSE TRY_TO_DOUBLE("wdsp")                 END              AS wind_knots,
        CASE WHEN "prcp"  >=  99  THEN NULL ELSE "prcp"           END              AS prcp_in
    FROM NEW_YORK_CITIBIKE_1.NOAA_GSOD.GSOD2014
    WHERE "wban" = '94728'    -- Central Park
),
/* -------- attach start / end neighborhoods via ZIP polygons ----------------- */
trip_neigh AS (
    SELECT
        t.trip_date,
        t.duration_min,
        src_c."neighborhood" AS start_neighborhood,
        dst_c."neighborhood" AS end_neighborhood
    FROM trips_2014 t
    /* start → ZIP → neighborhood */
    JOIN NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES.ZIP_CODES src_z
      ON ST_WITHIN(
            ST_MAKEPOINT(t."start_station_longitude", t."start_station_latitude"),
            TO_GEOGRAPHY(src_z."zip_code_geom"))
    JOIN NEW_YORK_CITIBIKE_1.CYCLISTIC.ZIP_CODES        src_c
      ON src_z."zip_code" = src_c."zip"::TEXT
    /* end → ZIP → neighborhood */
    JOIN NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES.ZIP_CODES dst_z
      ON ST_WITHIN(
            ST_MAKEPOINT(t."end_station_longitude", t."end_station_latitude"),
            TO_GEOGRAPHY(dst_z."zip_code_geom"))
    JOIN NEW_YORK_CITIBIKE_1.CYCLISTIC.ZIP_CODES        dst_c
      ON dst_z."zip_code" = dst_c."zip"::TEXT
),
/* -------- merge weather ------------------------------------------------------ */
trip_weather AS (
    SELECT
        n.start_neighborhood,
        n.end_neighborhood,
        n.duration_min,
        n.trip_date,
        MONTH(n.trip_date)                                            AS trip_month,
        ((w.temp_f - 32) * 5.0 / 9.0)                                 AS temp_c,
        (w.wind_knots * 0.514444)                                     AS wind_mps,
        (w.prcp_in   * 2.54)                                          AS precip_cm
    FROM trip_neigh n
    JOIN weather w
      ON n.trip_date = w.weather_date
),
/* -------- main aggregates ---------------------------------------------------- */
main_stats AS (
    SELECT
        start_neighborhood,
        end_neighborhood,
        COUNT(*)                                   AS total_trips,
        ROUND(AVG(duration_min), 1)                AS avg_duration_min,
        ROUND(AVG(temp_c),        1)               AS avg_temp_c,
        ROUND(AVG(wind_mps),      1)               AS avg_wind_speed_mps,
        ROUND(AVG(precip_cm),     1)               AS avg_precip_cm
    FROM trip_weather
    GROUP BY start_neighborhood, end_neighborhood
),
/* -------- busiest month per OD pair ----------------------------------------- */
top_months AS (
    SELECT
        start_neighborhood,
        end_neighborhood,
        trip_month,
        ROW_NUMBER() OVER (PARTITION BY start_neighborhood, end_neighborhood
                           ORDER BY COUNT(*) DESC, trip_month) AS rn
    FROM trip_weather
    GROUP BY start_neighborhood, end_neighborhood, trip_month
    QUALIFY rn = 1
)
/* -------- final result ------------------------------------------------------- */
SELECT
    m.start_neighborhood                    AS "start_neighborhood",
    m.end_neighborhood                      AS "end_neighborhood",
    m.total_trips                           AS "total_trips",
    m.avg_duration_min                      AS "avg_duration_min",
    m.avg_temp_c                            AS "avg_temp_c",
    m.avg_wind_speed_mps                    AS "avg_wind_speed_mps",
    m.avg_precip_cm                         AS "avg_precip_cm",
    t.trip_month                            AS "top_month"
FROM main_stats  m
JOIN top_months  t
  ON m.start_neighborhood = t.start_neighborhood
 AND m.end_neighborhood   = t.end_neighborhood
ORDER BY m.start_neighborhood, m.end_neighborhood;