/* 2014 NYC Citi Bike trips → neighbourhood pairs → Central Park weather */
WITH
/* ------------------------------------------------------------------ */
/* Central‑Park NOAA station codes                                    */
cp_station AS (
    SELECT DISTINCT "usaf", "wban"
    FROM NEW_YORK_CITIBIKE_1.NOAA_GSOD.STATIONS
    WHERE UPPER("name") LIKE '%CENTRAL PARK%'
),
/* Daily weather (Central Park) for 2014                              */
weather AS (
    SELECT
        TO_DATE(CONCAT_WS('-', "year","mo","da"))                    AS weather_date,
        CAST("temp"                   AS FLOAT)                      AS temp_f,
        CAST(NULLIF("wdsp",'999.9')   AS FLOAT)                      AS wind_knots,
        CAST(NULLIF("prcp",99.99)     AS FLOAT)                      AS prcp_in
    FROM NEW_YORK_CITIBIKE_1.NOAA_GSOD.GSOD2014 w
    JOIN cp_station s
      ON w."stn" = s."usaf"
     AND w."wban" = s."wban"
),
/* ------------------------------------------------------------------ */
/* ZIP polygons (as GEOGRAPHY) and neighbourhood lookup               */
geo_zip AS (
    SELECT
        "zip_code",
        ST_GEOGFROMWKB("zip_code_geom") AS zip_geom
    FROM NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES.ZIP_CODES
),
zip_nhood AS (
    SELECT
        CAST("zip" AS TEXT) AS "zip_code",
        "borough",
        "neighborhood"
    FROM NEW_YORK_CITIBIKE_1.CYCLISTIC.ZIP_CODES
),
/* ------------------------------------------------------------------ */
/* 2014 trips with geometry, date, duration                           */
trip_raw AS (
    SELECT
        ST_POINT("start_station_longitude","start_station_latitude") AS start_geom,
        ST_POINT("end_station_longitude"  ,"end_station_latitude")   AS end_geom,
        TO_DATE(TO_TIMESTAMP_NTZ("starttime"/1e6))                   AS trip_date,
        EXTRACT(MONTH FROM TO_TIMESTAMP_NTZ("starttime"/1e6))        AS trip_month,
        "tripduration"/60.0                                          AS duration_min
    FROM NEW_YORK_CITIBIKE_1.NEW_YORK_CITIBIKE.CITIBIKE_TRIPS
    WHERE TO_CHAR(TO_TIMESTAMP_NTZ("starttime"/1e6),'YYYY') = '2014'
),
/* ------------------------------------------------------------------ */
/* Attach ZIP codes using spatial containment                         */
trip_zip AS (
    SELECT
        tr.*,
        sz."zip_code" AS start_zip,
        ez."zip_code" AS end_zip
    FROM trip_raw tr
    LEFT JOIN geo_zip sz ON ST_WITHIN(tr.start_geom , sz.zip_geom)
    LEFT JOIN geo_zip ez ON ST_WITHIN(tr.end_geom   , ez.zip_geom)
),
/* Add borough / neighbourhood names                                  */
trip_nhood AS (
    SELECT
        tz.*,
        sn."borough"      AS start_borough,
        sn."neighborhood" AS start_neighborhood,
        en."borough"      AS end_borough,
        en."neighborhood" AS end_neighborhood
    FROM trip_zip tz
    LEFT JOIN zip_nhood sn ON tz.start_zip = sn."zip_code"
    LEFT JOIN zip_nhood en ON tz.end_zip   = en."zip_code"
    WHERE sn."neighborhood" IS NOT NULL
      AND en."neighborhood" IS NOT NULL
),
/* ------------------------------------------------------------------ */
/* Join with same‑day Central‑Park weather                            */
trip_weather AS (
    SELECT
        tn.*,
        w.temp_f,
        w.wind_knots,
        w.prcp_in
    FROM trip_nhood tn
    LEFT JOIN weather w
      ON tn.trip_date = w.weather_date
),
/* ------------------------------------------------------------------ */
/* Trip counts per neighbourhood pair & month (for modal month)       */
pair_month_counts AS (
    SELECT
        start_neighborhood,
        end_neighborhood,
        trip_month,
        COUNT(*) AS trips_in_month
    FROM trip_weather
    GROUP BY 1,2,3
),
pair_best_month AS (
    SELECT
        start_neighborhood,
        end_neighborhood,
        FIRST_VALUE(trip_month)
          OVER (PARTITION BY start_neighborhood, end_neighborhood
                ORDER BY trips_in_month DESC, trip_month) AS most_active_month
    FROM pair_month_counts
    QUALIFY ROW_NUMBER() OVER (PARTITION BY start_neighborhood, end_neighborhood
                               ORDER BY trips_in_month DESC, trip_month) = 1
),
/* ------------------------------------------------------------------ */
/* Aggregate required metrics                                         */
pair_stats AS (
    SELECT
        start_neighborhood,
        end_neighborhood,
        COUNT(*)                         AS total_trips,
        ROUND(AVG(duration_min),1)       AS avg_trip_minutes,
        ROUND(AVG(temp_f)     ,1)        AS avg_temp_f,
        ROUND(AVG(wind_knots)*0.5144,1)  AS avg_wind_mps,   -- knots → m/s
        ROUND(AVG(prcp_in)*2.54   ,1)    AS avg_prcp_cm     -- inches → cm
    FROM trip_weather
    GROUP BY 1,2
)
/* ------------------------------------------------------------------ */
SELECT
    ps.start_neighborhood,
    ps.end_neighborhood,
    ps.total_trips,
    ps.avg_trip_minutes,
    ps.avg_temp_f,
    ps.avg_wind_mps,
    ps.avg_prcp_cm,
    bm.most_active_month
FROM pair_stats      ps
JOIN pair_best_month bm
      ON ps.start_neighborhood = bm.start_neighborhood
     AND ps.end_neighborhood   = bm.end_neighborhood
ORDER BY
    ps.total_trips DESC NULLS LAST,
    ps.start_neighborhood,
    ps.end_neighborhood;