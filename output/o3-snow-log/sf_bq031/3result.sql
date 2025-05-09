/*  Daily Rochester (NY) weather, Jan 1 – Mar 31 2019
    – daily values (°C / cm / m s-1)
    – 8-day moving averages
    – differences between today’s MA and the MA from 1 … 8 days ago           */

WITH rochester_stations AS (   -- U.S. GSOD stations that contain “ROCHESTER”
    SELECT  "usaf" AS "stn",
            "wban"
    FROM    NOAA_DATA.NOAA_GSOD.STATIONS
    WHERE   "country" = 'US'
      AND   "name" ILIKE '%ROCHESTER%'
),
daily_raw AS (                 -- convert units for every Rochester station / day
    SELECT
        TO_DATE(
            CONCAT(
                g."year",'-',
                LPAD(g."mo",2,'0'),'-',
                LPAD(g."da",2,'0')
            )
        )                                                           AS "obs_date",
        ROUND( (g."temp" - 32) * 5.0/9.0 , 1)                       AS "temp_c",
        ROUND( CASE WHEN g."prcp" = 99.99 THEN NULL
                    ELSE g."prcp" * 2.54 END , 1)                   AS "prcp_cm",
        ROUND( CASE WHEN g."wdsp" = '999.9' THEN NULL
                    ELSE CAST(g."wdsp" AS FLOAT) * 0.514444 END ,1) AS "wind_ms"
    FROM    NOAA_DATA.NOAA_GSOD.GSOD2019 g
    JOIN    rochester_stations s
         ON g."stn" = s."stn"
        AND g."wban" = s."wban"
    WHERE   g."year" = '2019'
      AND   g."mo" IN ('01','02','03')          -- Jan-Mar 2019
),
daily AS (                     -- average in case >1 station per day
    SELECT
        "obs_date",
        AVG("temp_c")  AS "temp_c",
        AVG("prcp_cm") AS "prcp_cm",
        AVG("wind_ms") AS "wind_ms"
    FROM  daily_raw
    GROUP BY "obs_date"
),
ma8 AS (                        -- 8-day moving averages (current + 7 prev)
    SELECT
        d.*,
        ROUND(AVG("temp_c")  OVER (ORDER BY "obs_date"
                                   ROWS BETWEEN 7 PRECEDING AND CURRENT ROW),1) AS "temp_ma8",
        ROUND(AVG("prcp_cm") OVER (ORDER BY "obs_date"
                                   ROWS BETWEEN 7 PRECEDING AND CURRENT ROW),1) AS "prcp_ma8",
        ROUND(AVG("wind_ms") OVER (ORDER BY "obs_date"
                                   ROWS BETWEEN 7 PRECEDING AND CURRENT ROW),1) AS "wind_ma8"
    FROM daily d
)
SELECT
    "obs_date",
    "temp_c",
    "prcp_cm",
    "wind_ms",
    /* 8-day moving averages */
    "temp_ma8",
    "prcp_ma8",
    "wind_ma8",
    /* --- temp MA differences --- */
    ROUND("temp_ma8" - LAG("temp_ma8",1) OVER (ORDER BY "obs_date"),1) AS "temp_ma8_diff1",
    ROUND("temp_ma8" - LAG("temp_ma8",2) OVER (ORDER BY "obs_date"),1) AS "temp_ma8_diff2",
    ROUND("temp_ma8" - LAG("temp_ma8",3) OVER (ORDER BY "obs_date"),1) AS "temp_ma8_diff3",
    ROUND("temp_ma8" - LAG("temp_ma8",4) OVER (ORDER BY "obs_date"),1) AS "temp_ma8_diff4",
    ROUND("temp_ma8" - LAG("temp_ma8",5) OVER (ORDER BY "obs_date"),1) AS "temp_ma8_diff5",
    ROUND("temp_ma8" - LAG("temp_ma8",6) OVER (ORDER BY "obs_date"),1) AS "temp_ma8_diff6",
    ROUND("temp_ma8" - LAG("temp_ma8",7) OVER (ORDER BY "obs_date"),1) AS "temp_ma8_diff7",
    ROUND("temp_ma8" - LAG("temp_ma8",8) OVER (ORDER BY "obs_date"),1) AS "temp_ma8_diff8",
    /* --- prcp MA differences --- */
    ROUND("prcp_ma8" - LAG("prcp_ma8",1) OVER (ORDER BY "obs_date"),1) AS "prcp_ma8_diff1",
    ROUND("prcp_ma8" - LAG("prcp_ma8",2) OVER (ORDER BY "obs_date"),1) AS "prcp_ma8_diff2",
    ROUND("prcp_ma8" - LAG("prcp_ma8",3) OVER (ORDER BY "obs_date"),1) AS "prcp_ma8_diff3",
    ROUND("prcp_ma8" - LAG("prcp_ma8",4) OVER (ORDER BY "obs_date"),1) AS "prcp_ma8_diff4",
    ROUND("prcp_ma8" - LAG("prcp_ma8",5) OVER (ORDER BY "obs_date"),1) AS "prcp_ma8_diff5",
    ROUND("prcp_ma8" - LAG("prcp_ma8",6) OVER (ORDER BY "obs_date"),1) AS "prcp_ma8_diff6",
    ROUND("prcp_ma8" - LAG("prcp_ma8",7) OVER (ORDER BY "obs_date"),1) AS "prcp_ma8_diff7",
    ROUND("prcp_ma8" - LAG("prcp_ma8",8) OVER (ORDER BY "obs_date"),1) AS "prcp_ma8_diff8",
    /* --- wind MA differences --- */
    ROUND("wind_ma8" - LAG("wind_ma8",1) OVER (ORDER BY "obs_date"),1) AS "wind_ma8_diff1",
    ROUND("wind_ma8" - LAG("wind_ma8",2) OVER (ORDER BY "obs_date"),1) AS "wind_ma8_diff2",
    ROUND("wind_ma8" - LAG("wind_ma8",3) OVER (ORDER BY "obs_date"),1) AS "wind_ma8_diff3",
    ROUND("wind_ma8" - LAG("wind_ma8",4) OVER (ORDER BY "obs_date"),1) AS "wind_ma8_diff4",
    ROUND("wind_ma8" - LAG("wind_ma8",5) OVER (ORDER BY "obs_date"),1) AS "wind_ma8_diff5",
    ROUND("wind_ma8" - LAG("wind_ma8",6) OVER (ORDER BY "obs_date"),1) AS "wind_ma8_diff6",
    ROUND("wind_ma8" - LAG("wind_ma8",7) OVER (ORDER BY "obs_date"),1) AS "wind_ma8_diff7",
    ROUND("wind_ma8" - LAG("wind_ma8",8) OVER (ORDER BY "obs_date"),1) AS "wind_ma8_diff8"
FROM   ma8
WHERE  "obs_date" BETWEEN '2019-01-09' AND '2019-03-31'   -- first complete MA onward
ORDER  BY "obs_date";