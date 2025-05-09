-- Daily Rochester (USAF 725290) weather, Jan-1 – Mar-31 2019
--  • values converted to °C / cm / m s-1
--  • 8-day moving-averages (MA8) for each variable
--  • MA8 differences vs. the previous 1-…-8 days (lag1-lag8)
--  • output begins 2019-01-09 (first row with a complete 8-day window)

WITH base AS (           -- convert the daily data
    SELECT
        TO_DATE( LPAD("year",4,'0')||'-'||LPAD("mo",2,'0')||'-'||LPAD("da",2,'0') ) AS "date",
        ROUND( ( "temp" - 32 ) * 5.0/9.0 , 1 )                        AS "temp_c",
        ROUND( CASE WHEN "prcp" = 99.99 THEN NULL
                    ELSE "prcp" * 2.54 END , 1 )                     AS "prcp_cm",
        ROUND( TRY_CAST("wdsp" AS FLOAT) * 0.514444 , 1 )            AS "wind_ms"
    FROM NOAA_DATA.NOAA_GSOD.GSOD2019
    WHERE "year" = '2019'
      AND "mo"   IN ('01','02','03')
      AND "stn"  = '725290'        -- Rochester (Greater Rochester Int’l AP)
),
ma AS (                 -- 8-day moving averages (current day + 7 prior)
    SELECT
        "date",
        "temp_c",
        "prcp_cm",
        "wind_ms",
        ROUND( AVG("temp_c")  OVER(ORDER BY "date"
                                   ROWS BETWEEN 7 PRECEDING AND CURRENT ROW) , 1 ) AS "temp_ma8",
        ROUND( AVG("prcp_cm") OVER(ORDER BY "date"
                                   ROWS BETWEEN 7 PRECEDING AND CURRENT ROW) , 1 ) AS "prcp_ma8",
        ROUND( AVG("wind_ms") OVER(ORDER BY "date"
                                   ROWS BETWEEN 7 PRECEDING AND CURRENT ROW) , 1 ) AS "wind_ma8"
    FROM base
)

SELECT
    "date",
    "temp_c",
    "prcp_cm",
    "wind_ms",
    "temp_ma8",
    "prcp_ma8",
    "wind_ma8",

    /*  ‑- temperature MA8 differences  */
    ROUND("temp_ma8" - LAG("temp_ma8",1) OVER(ORDER BY "date"),1) AS "temp_diff_lag1",
    ROUND("temp_ma8" - LAG("temp_ma8",2) OVER(ORDER BY "date"),1) AS "temp_diff_lag2",
    ROUND("temp_ma8" - LAG("temp_ma8",3) OVER(ORDER BY "date"),1) AS "temp_diff_lag3",
    ROUND("temp_ma8" - LAG("temp_ma8",4) OVER(ORDER BY "date"),1) AS "temp_diff_lag4",
    ROUND("temp_ma8" - LAG("temp_ma8",5) OVER(ORDER BY "date"),1) AS "temp_diff_lag5",
    ROUND("temp_ma8" - LAG("temp_ma8",6) OVER(ORDER BY "date"),1) AS "temp_diff_lag6",
    ROUND("temp_ma8" - LAG("temp_ma8",7) OVER(ORDER BY "date"),1) AS "temp_diff_lag7",
    ROUND("temp_ma8" - LAG("temp_ma8",8) OVER(ORDER BY "date"),1) AS "temp_diff_lag8",

    /*  ‑- precipitation MA8 differences  */
    ROUND("prcp_ma8" - LAG("prcp_ma8",1) OVER(ORDER BY "date"),1) AS "prcp_diff_lag1",
    ROUND("prcp_ma8" - LAG("prcp_ma8",2) OVER(ORDER BY "date"),1) AS "prcp_diff_lag2",
    ROUND("prcp_ma8" - LAG("prcp_ma8",3) OVER(ORDER BY "date"),1) AS "prcp_diff_lag3",
    ROUND("prcp_ma8" - LAG("prcp_ma8",4) OVER(ORDER BY "date"),1) AS "prcp_diff_lag4",
    ROUND("prcp_ma8" - LAG("prcp_ma8",5) OVER(ORDER BY "date"),1) AS "prcp_diff_lag5",
    ROUND("prcp_ma8" - LAG("prcp_ma8",6) OVER(ORDER BY "date"),1) AS "prcp_diff_lag6",
    ROUND("prcp_ma8" - LAG("prcp_ma8",7) OVER(ORDER BY "date"),1) AS "prcp_diff_lag7",
    ROUND("prcp_ma8" - LAG("prcp_ma8",8) OVER(ORDER BY "date"),1) AS "prcp_diff_lag8",

    /*  ‑- wind-speed MA8 differences  */
    ROUND("wind_ma8" - LAG("wind_ma8",1) OVER(ORDER BY "date"),1) AS "wind_diff_lag1",
    ROUND("wind_ma8" - LAG("wind_ma8",2) OVER(ORDER BY "date"),1) AS "wind_diff_lag2",
    ROUND("wind_ma8" - LAG("wind_ma8",3) OVER(ORDER BY "date"),1) AS "wind_diff_lag3",
    ROUND("wind_ma8" - LAG("wind_ma8",4) OVER(ORDER BY "date"),1) AS "wind_diff_lag4",
    ROUND("wind_ma8" - LAG("wind_ma8",5) OVER(ORDER BY "date"),1) AS "wind_diff_lag5",
    ROUND("wind_ma8" - LAG("wind_ma8",6) OVER(ORDER BY "date"),1) AS "wind_diff_lag6",
    ROUND("wind_ma8" - LAG("wind_ma8",7) OVER(ORDER BY "date"),1) AS "wind_diff_lag7",
    ROUND("wind_ma8" - LAG("wind_ma8",8) OVER(ORDER BY "date"),1) AS "wind_diff_lag8"

FROM ma
WHERE "date" BETWEEN '2019-01-09' AND '2019-03-31'
ORDER BY "date";