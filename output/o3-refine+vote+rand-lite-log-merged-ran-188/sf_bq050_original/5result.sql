/* Bike trips 2014 – neighbourhood‑to‑neighbourhood flows enriched with Central Park weather */

WITH central_park AS (          -- Central Park GSOD station
    SELECT DISTINCT
           "usaf",
           "wban"
    FROM   NEW_YORK_CITIBIKE_1.NOAA_GSOD.STATIONS
    WHERE  UPPER("name") LIKE '%CENTRAL PARK%'
      AND  "state" = 'NY'
    LIMIT  1
),

weather_2014 AS (               -- daily Central‑Park weather
    SELECT
        TO_DATE("year"||'-'||LPAD("mo",2,'0')||'-'||LPAD("da",2,'0'))      AS wx_date,
        CAST(NULLIF("temp",  9999.9) AS FLOAT)   AS temp_f,        -- °F
        CAST(NULLIF("wdsp", '999.9') AS FLOAT)   AS wind_knots,    -- knots
        CAST(NULLIF("prcp",  99.99)  AS FLOAT)   AS prcp_in        -- inches
    FROM   NEW_YORK_CITIBIKE_1.NOAA_GSOD.GSOD2014  g
    JOIN   central_park  cp
           ON g."stn"  = cp."usaf"
          AND g."wban" = cp."wban"
),

trips_2014 AS (                 -- trips in 2014 with date parts
    SELECT  t.*,
            TO_TIMESTAMP_LTZ("starttime"/1000000)                         AS start_ts,
            TO_DATE(TO_TIMESTAMP_LTZ("starttime"/1000000))                AS ride_date,
            EXTRACT(MONTH FROM TO_TIMESTAMP_LTZ("starttime"/1000000))     AS ride_month
    FROM    NEW_YORK_CITIBIKE_1.NEW_YORK_CITIBIKE.CITIBIKE_TRIPS t
    WHERE   YEAR(TO_TIMESTAMP_LTZ("starttime"/1000000)) = 2014
),

/* spatial join to ZIP polygons */
trip_zips AS (
    SELECT  tr.*,
            z_from."zip_code" AS start_zip,
            z_to."zip_code"   AS end_zip
    FROM    trips_2014 tr
    LEFT JOIN NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES.ZIP_CODES z_from
           ON ST_WITHIN(
                  ST_MAKEPOINT(tr."start_station_longitude", tr."start_station_latitude"),
                  TO_GEOGRAPHY(z_from."zip_code_geom")
              )
    LEFT JOIN NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES.ZIP_CODES z_to
           ON ST_WITHIN(
                  ST_MAKEPOINT(tr."end_station_longitude",   tr."end_station_latitude"),
                  TO_GEOGRAPHY(z_to."zip_code_geom")
              )
),

/* attach weather */
trip_wx AS (
    SELECT  tz.*,
            wx.temp_f,
            wx.wind_knots,
            wx.prcp_in
    FROM    trip_zips tz
    LEFT JOIN weather_2014 wx
           ON tz.ride_date = wx.wx_date
),

/* map ZIPs to neighbourhoods */
trip_neigh AS (
    SELECT
        cs_from."neighborhood" AS start_neigh,
        cs_to."neighborhood"   AS end_neigh,
        tz."tripduration",
        tz.ride_month,
        tz.temp_f,
        tz.wind_knots,
        tz.prcp_in
    FROM   trip_wx tz
    LEFT  JOIN NEW_YORK_CITIBIKE_1.CYCLISTIC.ZIP_CODES cs_from
           ON cs_from."zip" = tz.start_zip
    LEFT  JOIN NEW_YORK_CITIBIKE_1.CYCLISTIC.ZIP_CODES cs_to
           ON cs_to."zip"  = tz.end_zip
    WHERE  cs_from."neighborhood" IS NOT NULL
      AND  cs_to."neighborhood"   IS NOT NULL
),

/* aggregate statistics */
stats AS (
    SELECT
        start_neigh,
        end_neigh,
        COUNT(*)                                           AS total_trips,
        ROUND(AVG("tripduration")/60, 1)                   AS avg_trip_minutes,
        ROUND(AVG(temp_f),                   1)            AS avg_temp_f,
        ROUND(AVG(wind_knots)*0.514444,      1)            AS avg_wind_mps,   -- knots ➜ m s⁻¹
        ROUND(AVG(prcp_in)*2.54,             1)            AS avg_prcp_cm     -- inches ➜ cm
    FROM   trip_neigh
    GROUP  BY start_neigh, end_neigh
),

/* busiest month per pair */
top_month AS (
    SELECT
        start_neigh,
        end_neigh,
        ride_month AS most_active_month,
        ROW_NUMBER() OVER (PARTITION BY start_neigh, end_neigh
                           ORDER BY COUNT(*) DESC, ride_month) AS rn
    FROM   trip_neigh
    GROUP  BY start_neigh, end_neigh, ride_month
    QUALIFY rn = 1
)

/* final result */
SELECT
    s.start_neigh        AS "START_NEIGHBORHOOD",
    s.end_neigh          AS "END_NEIGHBORHOOD",
    s.total_trips        AS "TOTAL_TRIPS",
    s.avg_trip_minutes   AS "AVG_TRIP_MINUTES",
    s.avg_temp_f         AS "AVG_TEMP_F",
    s.avg_wind_mps       AS "AVG_WIND_MPS",
    s.avg_prcp_cm        AS "AVG_PRCP_CM",
    tm.most_active_month AS "MOST_ACTIVE_MONTH"
FROM   stats     s
JOIN   top_month tm
  ON   s.start_neigh = tm.start_neigh
 AND   s.end_neigh   = tm.end_neigh
ORDER BY s.total_trips DESC NULLS LAST,
         s.start_neigh,
         s.end_neigh;