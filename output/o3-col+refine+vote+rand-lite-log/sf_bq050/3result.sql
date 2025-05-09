/* Weather-adjusted Citi Bike flows between NYC neighbourhoods (2014) */

WITH
/* ───────────────────────── 1 ── Central-Park daily weather ───────────────────────── */
central_park AS (
    SELECT "usaf","wban"
    FROM   NEW_YORK_CITIBIKE_1.NOAA_GSOD."STATIONS"
    WHERE  "name" ILIKE '%central park%' AND "state" = 'NY'
    ORDER  BY "end" DESC
    LIMIT  1
),
wx AS (
    SELECT
        TO_DATE(CONCAT_WS('-',"year",LPAD("mo",2,'0'),LPAD("da",2,'0')))     AS wx_date,
        CAST("temp"                 AS FLOAT)                                AS temp_f,      -- °F
        CAST(NULLIF("wdsp",'999.9') AS FLOAT)                                AS wdsp_knots,  -- knots
        CAST(NULLIF("prcp",99.99)   AS FLOAT)                                AS prcp_in      -- inches
    FROM NEW_YORK_CITIBIKE_1.NOAA_GSOD."GSOD2014" w
    JOIN central_park cp
      ON w."stn"  = cp."usaf"
     AND w."wban" = cp."wban"
),

/* ───────────────────────── 2 ── 2014 Citi Bike trips + geography points ───────────── */
trips14 AS (
    SELECT
        t."tripduration",
        TO_DATE(TO_TIMESTAMP_NTZ(t."starttime"/1e6))               AS start_d,
        EXTRACT(month FROM TO_TIMESTAMP_NTZ(t."starttime"/1e6))    AS trip_month,
        -- geography points as WKT strings
        TO_GEOGRAPHY('POINT('||t."start_station_longitude"||' '||
                              t."start_station_latitude" ||')')    AS g_start,
        TO_GEOGRAPHY('POINT('||t."end_station_longitude"  ||' '||
                              t."end_station_latitude"   ||')')    AS g_end
    FROM NEW_YORK_CITIBIKE_1.NEW_YORK_CITIBIKE."CITIBIKE_TRIPS" t
    WHERE t."starttime" BETWEEN 1388534400000000   -- 2014-01-01
                           AND     1420070399000000 -- 2014-12-31
),

/* ───────────────────────── 3 ── Match start / end points to NYC ZIP polygons ───────── */
start_zip AS (
    SELECT t.*, z."zip_code" AS start_zip
    FROM   trips14 t
    JOIN   NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES."ZIP_CODES" z
      ON   z."state_code" = 'NY'
     AND   ST_CONTAINS(TO_GEOGRAPHY(z."zip_code_geom"), t.g_start)
),
both_zips AS (
    SELECT s.*, z."zip_code" AS end_zip
    FROM   start_zip s
    JOIN   NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES."ZIP_CODES" z
      ON   z."state_code" = 'NY'
     AND   ST_CONTAINS(TO_GEOGRAPHY(z."zip_code_geom"), s.g_end)
),

/* ───────────────────────── 4 ── Add Cyclistic neighbourhood names ──────────────────── */
with_neigh AS (
    SELECT  b.*,
            sn."neighborhood" AS start_neigh,
            en."neighborhood" AS end_neigh
    FROM   both_zips b
    LEFT   JOIN NEW_YORK_CITIBIKE_1.CYCLISTIC."ZIP_CODES" sn
           ON sn."zip"::TEXT = b.start_zip
    LEFT   JOIN NEW_YORK_CITIBIKE_1.CYCLISTIC."ZIP_CODES" en
           ON en."zip"::TEXT = b.end_zip
    WHERE  sn."neighborhood" IS NOT NULL
      AND  en."neighborhood" IS NOT NULL
),

/* ───────────────────────── 5 ── Attach same-day Central-Park weather ──────────────── */
trip_wx AS (
    SELECT w.*,
           x.temp_f,
           x.wdsp_knots,
           x.prcp_in
    FROM   with_neigh w
    LEFT   JOIN wx x
           ON x.wx_date = w.start_d
),

/* ───────────────────────── 6a ── Monthly counts per neighbourhood pair ─────────────── */
pair_month AS (
    SELECT
        start_neigh,
        end_neigh,
        trip_month,
        COUNT(*) AS month_trips
    FROM trip_wx
    GROUP BY start_neigh, end_neigh, trip_month
),
busiest AS (   -- pick highest-volume month per pair
    SELECT start_neigh,
           end_neigh,
           trip_month AS busiest_month
    FROM (
        SELECT *,
               ROW_NUMBER() OVER (PARTITION BY start_neigh,end_neigh
                                  ORDER BY month_trips DESC) AS rn
        FROM pair_month
    )
    WHERE rn = 1
),

/* ───────────────────────── 6b ── Final metrics per neighbourhood pair ─────────────── */
agg AS (
    SELECT
        tw.start_neigh,
        tw.end_neigh,
        COUNT(*)                              AS trip_count,
        ROUND(AVG(tw."tripduration")/60, 1)   AS avg_trip_min,
        ROUND(AVG(temp_f)             , 1)    AS avg_temp_f,
        ROUND(AVG(wdsp_knots)*0.514444, 1)    AS avg_wind_mps,
        ROUND(AVG(prcp_in)*2.54       , 1)    AS avg_prcp_cm
    FROM trip_wx tw
    GROUP BY tw.start_neigh, tw.end_neigh
)

/* ───────────────────────── 7 ── Combine metrics with busiest month ─────────────────── */
SELECT a.*,
       b.busiest_month
FROM   agg      a
LEFT   JOIN busiest b
  ON   b.start_neigh = a.start_neigh
 AND   b.end_neigh   = a.end_neigh
ORDER  BY trip_count DESC NULLS LAST;