WITH base AS (
    SELECT
        TO_DATE("year"||'-'||"mo"||'-'||"da")                                          AS "date",
        ROUND( ("temp" - 32) * 5 / 9 , 1 )                                             AS "t_c",
        ROUND( "prcp" * 2.54 , 1 )                                                     AS "prcp_cm",
        ROUND( "wdsp"::FLOAT * 0.514444 , 1 )                                          AS "wind_ms"
    FROM NOAA_DATA.NOAA_GSOD.GSOD2019
    WHERE "stn"  = '725290'              -- Rochester (USAF 725290)
      AND "wban" = '14768'               -- Rochester (WBAN 14768)
      AND TO_DATE("year"||'-'||"mo"||'-'||"da") BETWEEN '2019-01-01' AND '2019-03-31'
),
ma AS (      -- 8-day (current + prior 7) moving averages
    SELECT
        "date",
        "t_c",
        "prcp_cm",
        "wind_ms",
        ROUND( AVG("t_c")      OVER (ORDER BY "date" ROWS BETWEEN 7 PRECEDING AND CURRENT ROW), 1 ) AS "t_ma8",
        ROUND( AVG("prcp_cm")  OVER (ORDER BY "date" ROWS BETWEEN 7 PRECEDING AND CURRENT ROW), 1 ) AS "p_ma8",
        ROUND( AVG("wind_ms")  OVER (ORDER BY "date" ROWS BETWEEN 7 PRECEDING AND CURRENT ROW), 1 ) AS "w_ma8"
    FROM base
)
SELECT
    "date",
    /* daily values */
    "t_c",
    "prcp_cm",
    "wind_ms",
    /* 8-day moving averages */
    "t_ma8",
    "p_ma8",
    "w_ma8",
    /* temperature lag-diffs */
    ROUND("t_ma8" - LAG("t_ma8",1) OVER (ORDER BY "date"),1) AS "t_lag1",
    ROUND("t_ma8" - LAG("t_ma8",2) OVER (ORDER BY "date"),1) AS "t_lag2",
    ROUND("t_ma8" - LAG("t_ma8",3) OVER (ORDER BY "date"),1) AS "t_lag3",
    ROUND("t_ma8" - LAG("t_ma8",4) OVER (ORDER BY "date"),1) AS "t_lag4",
    ROUND("t_ma8" - LAG("t_ma8",5) OVER (ORDER BY "date"),1) AS "t_lag5",
    ROUND("t_ma8" - LAG("t_ma8",6) OVER (ORDER BY "date"),1) AS "t_lag6",
    ROUND("t_ma8" - LAG("t_ma8",7) OVER (ORDER BY "date"),1) AS "t_lag7",
    ROUND("t_ma8" - LAG("t_ma8",8) OVER (ORDER BY "date"),1) AS "t_lag8",
    /* precipitation lag-diffs */
    ROUND("p_ma8" - LAG("p_ma8",1) OVER (ORDER BY "date"),1) AS "p_lag1",
    ROUND("p_ma8" - LAG("p_ma8",2) OVER (ORDER BY "date"),1) AS "p_lag2",
    ROUND("p_ma8" - LAG("p_ma8",3) OVER (ORDER BY "date"),1) AS "p_lag3",
    ROUND("p_ma8" - LAG("p_ma8",4) OVER (ORDER BY "date"),1) AS "p_lag4",
    ROUND("p_ma8" - LAG("p_ma8",5) OVER (ORDER BY "date"),1) AS "p_lag5",
    ROUND("p_ma8" - LAG("p_ma8",6) OVER (ORDER BY "date"),1) AS "p_lag6",
    ROUND("p_ma8" - LAG("p_ma8",7) OVER (ORDER BY "date"),1) AS "p_lag7",
    ROUND("p_ma8" - LAG("p_ma8",8) OVER (ORDER BY "date"),1) AS "p_lag8",
    /* wind-speed lag-diffs */
    ROUND("w_ma8" - LAG("w_ma8",1) OVER (ORDER BY "date"),1) AS "w_lag1",
    ROUND("w_ma8" - LAG("w_ma8",2) OVER (ORDER BY "date"),1) AS "w_lag2",
    ROUND("w_ma8" - LAG("w_ma8",3) OVER (ORDER BY "date"),1) AS "w_lag3",
    ROUND("w_ma8" - LAG("w_ma8",4) OVER (ORDER BY "date"),1) AS "w_lag4",
    ROUND("w_ma8" - LAG("w_ma8",5) OVER (ORDER BY "date"),1) AS "w_lag5",
    ROUND("w_ma8" - LAG("w_ma8",6) OVER (ORDER BY "date"),1) AS "w_lag6",
    ROUND("w_ma8" - LAG("w_ma8",7) OVER (ORDER BY "date"),1) AS "w_lag7",
    ROUND("w_ma8" - LAG("w_ma8",8) OVER (ORDER BY "date"),1) AS "w_lag8"
FROM ma
WHERE "date" >= '2019-01-09'   -- first day with complete 8-day window
ORDER BY "date";