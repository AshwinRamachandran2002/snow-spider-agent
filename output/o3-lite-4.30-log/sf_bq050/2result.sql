WITH -------------------------------------------------------------
-- 1. Citi Bike trips started in calendar‑year 2014
trips_2014 AS (
    SELECT
        TO_TIMESTAMP_NTZ("starttime" / 1000000)             AS trip_ts,       -- local NYC time
        "tripduration",
        "start_station_latitude"                            AS s_lat,
        "start_station_longitude"                           AS s_lon,
        "end_station_latitude"                              AS e_lat,
        "end_station_longitude"                             AS e_lon
    FROM "NEW_YORK_CITIBIKE_1"."NEW_YORK_CITIBIKE"."CITIBIKE_TRIPS"
    WHERE DATE_PART('year', TO_TIMESTAMP_NTZ("starttime" / 1000000)) = 2014
), -------------------------------------------------------------
-- 2. New‑York‑state ZIP polygons as GEOGRAPHY
ny_zips AS (
    SELECT
        "zip_code",
        TO_GEOGRAPHY("zip_code_geom")                       AS zip_geom
    FROM "NEW_YORK_CITIBIKE_1"."GEO_US_BOUNDARIES"."ZIP_CODES"
    WHERE "state_code" = 'NY'
), -------------------------------------------------------------
-- 3. Determine ZIP of trip START point
start_zip AS (
    SELECT
        t.*,
        z."zip_code"                                        AS start_zip
    FROM trips_2014 t
    JOIN ny_zips z
      ON ST_CONTAINS(z.zip_geom, ST_MAKEPOINT(t.s_lon, t.s_lat))
), -------------------------------------------------------------
-- 4. Determine ZIP of trip END point
start_end_zip AS (
    SELECT
        s.*,
        z."zip_code"                                        AS end_zip
    FROM start_zip s
    JOIN ny_zips z
      ON ST_CONTAINS(z.zip_geom, ST_MAKEPOINT(s.e_lon, s.e_lat))
), -------------------------------------------------------------
-- 5. Attach neighbourhood names and derive date / month columns
trip_neigh AS (
    SELECT
        se.*,
        cs."neighborhood"                                   AS start_neighborhood,
        ce."neighborhood"                                   AS end_neighborhood,
        DATE_TRUNC('day', se.trip_ts)                       AS trip_date,
        DATE_PART('month', se.trip_ts)                      AS trip_month
    FROM start_end_zip se
    JOIN "NEW_YORK_CITIBIKE_1"."CYCLISTIC"."ZIP_CODES" cs
      ON cs."zip" = TO_NUMBER(se.start_zip)
    JOIN "NEW_YORK_CITIBIKE_1"."CYCLISTIC"."ZIP_CODES" ce
      ON ce."zip" = TO_NUMBER(se.end_zip)
), -------------------------------------------------------------
-- 6. Daily Central‑Park weather (filter out sentinel missing values)
weather_2014 AS (
    SELECT
        TO_DATE(TO_VARCHAR("year" || '-' || "mo" || '-' || "da")) AS wx_date,
        AVG("temp")                                 AS avg_temp_f,      -- °F
        AVG(TRY_TO_NUMBER("wdsp"))                  AS avg_wind_kn,    -- knots
        AVG("prcp")                                 AS avg_prcp_in     -- inches
    FROM "NEW_YORK_CITIBIKE_1"."NOAA_GSOD"."GSOD2014"
    WHERE "wban" = '94728'           -- Central Park station
      AND "year" = '2014'
      AND "temp"  <> 9999.9
      AND TRY_TO_NUMBER("wdsp") <> 999.9
      AND "prcp"  <> 99.99
    GROUP BY wx_date
), -------------------------------------------------------------
-- 7. Enrich trips with same‑day weather; convert to metric units
trips_wx AS (
    SELECT
        n.start_neighborhood,
        n.end_neighborhood,
        n.trip_month,
        n."tripduration",
        (w.avg_temp_f - 32) * 5/9                    AS temp_c,                 -- °C
        w.avg_wind_kn * 0.514444                     AS wind_mps,               -- m s‑1
        w.avg_prcp_in * 2.54                         AS prcp_cm                 -- cm
    FROM trip_neigh n
    JOIN weather_2014 w
      ON w.wx_date = n.trip_date
), -------------------------------------------------------------
-- 8. Aggregate metrics for each neighbourhood pair
pair_stats AS (
    SELECT
        start_neighborhood,
        end_neighborhood,
        COUNT(*)                                        AS total_trips,
        ROUND(AVG("tripduration") / 60, 1)              AS avg_duration_min,
        ROUND(AVG(temp_c),       1)                     AS avg_temp_c,
        ROUND(AVG(wind_mps),     1)                     AS avg_wind_speed_mps,
        ROUND(AVG(prcp_cm),      1)                     AS avg_precip_cm
    FROM trips_wx
    GROUP BY start_neighborhood, end_neighborhood
), -------------------------------------------------------------
-- 9. Identify the month with the highest trip count per pair
top_months AS (
    SELECT
        start_neighborhood,
        end_neighborhood,
        trip_month                                         AS top_month,
        ROW_NUMBER() OVER (PARTITION BY start_neighborhood, end_neighborhood
                           ORDER BY COUNT(*) DESC)         AS rn
    FROM trips_wx
    GROUP BY start_neighborhood, end_neighborhood, trip_month
    QUALIFY rn = 1
) -------------------------------------------------------------
-- 10. Final result set
SELECT
    p.start_neighborhood,
    p.end_neighborhood,
    p.total_trips,
    p.avg_duration_min,
    p.avg_temp_c,
    p.avg_wind_speed_mps,
    p.avg_precip_cm,
    t.top_month
FROM pair_stats p
JOIN top_months t
  ON  p.start_neighborhood = t.start_neighborhood
  AND p.end_neighborhood   = t.end_neighborhood
ORDER BY p.total_trips DESC NULLS LAST;