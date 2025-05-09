WITH july_runs AS (   /* July‑2019 GFS runs whose grid‑node lies within 5 km of 26.75 N, 51.5 E   */
    SELECT *
    FROM NOAA_GLOBAL_FORECAST_SYSTEM.NOAA_GLOBAL_FORECAST_SYSTEM.NOAA_GFS0P25
    WHERE "creation_time"
          BETWEEN 1561939200000000        /* 2019‑07‑01 00:00:00 UTC */
              AND 1564617599000000        /* 2019‑07‑31 23:59:59 UTC */
      AND ST_DISTANCE(
            TO_GEOGRAPHY('POINT(26.75 51.5)'),   /* note: data stored lat‑lon, so POINT(lat lon) */
            TO_GEOGRAPHY("geography")
          ) <= 5000                              /* 5‑km radius */
), flat AS (        /* keep only the “next‑day” (24‑h lead) forecast slices */
    SELECT
        TO_DATE( TO_TIMESTAMP_LTZ(f.value:"time"::NUMBER / 1000000) )  AS forecast_date,
        TO_TIMESTAMP_LTZ(f.value:"time"::NUMBER / 1000000)            AS valid_ts,
        f.value:"temperature_2m_above_ground"::FLOAT                  AS temp_c,      -- already in °C
        f.value:"total_precipitation_surface"::FLOAT                  AS precip_mm,
        f.value:"cloud_cover_total_cloud_layer"::FLOAT                AS cloud_pct
    FROM july_runs r,
         LATERAL FLATTEN( INPUT => r."forecast" ) f
    WHERE f.value:"hours"::NUMBER = 24
), daily AS (       /* aggregate to daily metrics */
    SELECT
        forecast_date,
        MAX(temp_c)                                   AS max_temp_c,
        MIN(temp_c)                                   AS min_temp_c,
        AVG(temp_c)                                   AS avg_temp_c,
        SUM(precip_mm)                                AS total_precip_mm,
        AVG( CASE WHEN DATE_PART('hour', valid_ts) BETWEEN 10 AND 17
                  THEN cloud_pct END )                AS avg_cloud_pct
    FROM flat
    GROUP BY forecast_date
)
SELECT
    TO_CHAR(forecast_date,'YYYY-MM-DD')                                            AS forecast_date,
    ROUND( max_temp_c * 9/5 + 32 , 4)                                              AS max_temp_f,
    ROUND( min_temp_c * 9/5 + 32 , 4)                                              AS min_temp_f,
    ROUND( avg_temp_c * 9/5 + 32 , 4)                                              AS avg_temp_f,
    ROUND( total_precip_mm , 4)                                                    AS total_precipitation_mm,
    ROUND( COALESCE(avg_cloud_pct,0) , 4)                                          AS avg_cloud_cover_pct,
    ROUND( CASE WHEN (avg_temp_c * 9/5 + 32) < 32
                THEN total_precip_mm ELSE 0 END , 4)                               AS total_snowfall_mm,
    ROUND( CASE WHEN (avg_temp_c * 9/5 + 32) >= 32
                THEN total_precip_mm ELSE 0 END , 4)                               AS total_rainfall_mm
FROM daily
ORDER BY forecast_date;