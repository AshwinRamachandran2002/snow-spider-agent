/*  Daily Rochester (NY, USA – station 725290-14768) weather, 
    1-Jan-2019 – 31-Mar-2019
    – metric units (°C, cm, m s-1)
    – 8-day moving means (current day + 7 previous)
    – differences between today’s moving mean and those
      from the previous 1…8 days (lag-1 … lag-8)
*/
WITH base AS (   -- raw daily values, metric & rounded
    SELECT
        TO_DATE("year"||'-'||"mo"||'-'||"da")                      AS "obs_date",
        ROUND( ( "temp" - 32 ) * 5/9 , 1)                          AS "temp_C",
        ROUND( "prcp" * 2.54 , 1)                                  AS "prcp_cm",
        ROUND( "wdsp"::FLOAT * 0.514444 , 1)                       AS "wdsp_mps"
    FROM NOAA_DATA.NOAA_GSOD."GSOD2019"
    WHERE "stn"  = '725290'        -- Greater Rochester Intl Airport
      AND "wban" = '14768'
      AND TO_DATE("year"||'-'||"mo"||'-'||"da")
          BETWEEN '2019-01-01' AND '2019-03-31'
),
ma AS (          -- 8-day moving averages, rounded
    SELECT
        b.*,
        ROUND( AVG("temp_C")  OVER (ORDER BY "obs_date"
                                    ROWS BETWEEN 7 PRECEDING AND CURRENT ROW) ,1)  AS "temp_ma8",
        ROUND( AVG("prcp_cm") OVER (ORDER BY "obs_date"
                                    ROWS BETWEEN 7 PRECEDING AND CURRENT ROW) ,1)  AS "prcp_ma8",
        ROUND( AVG("wdsp_mps")OVER (ORDER BY "obs_date"
                                    ROWS BETWEEN 7 PRECEDING AND CURRENT ROW) ,1)  AS "wdsp_ma8"
    FROM base b
)
SELECT
    "obs_date",
    /* daily metrics */
    "temp_C",  "prcp_cm",  "wdsp_mps",
    /* 8-day moving means */
    "temp_ma8","prcp_ma8","wdsp_ma8",
    /* differences vs. previous 1-8 days – temperature */
    ROUND("temp_ma8" - LAG("temp_ma8",1) OVER (ORDER BY "obs_date"),1)  AS "temp_ma8_diff_lag1",
    ROUND("temp_ma8" - LAG("temp_ma8",2) OVER (ORDER BY "obs_date"),1)  AS "temp_ma8_diff_lag2",
    ROUND("temp_ma8" - LAG("temp_ma8",3) OVER (ORDER BY "obs_date"),1)  AS "temp_ma8_diff_lag3",
    ROUND("temp_ma8" - LAG("temp_ma8",4) OVER (ORDER BY "obs_date"),1)  AS "temp_ma8_diff_lag4",
    ROUND("temp_ma8" - LAG("temp_ma8",5) OVER (ORDER BY "obs_date"),1)  AS "temp_ma8_diff_lag5",
    ROUND("temp_ma8" - LAG("temp_ma8",6) OVER (ORDER BY "obs_date"),1)  AS "temp_ma8_diff_lag6",
    ROUND("temp_ma8" - LAG("temp_ma8",7) OVER (ORDER BY "obs_date"),1)  AS "temp_ma8_diff_lag7",
    ROUND("temp_ma8" - LAG("temp_ma8",8) OVER (ORDER BY "obs_date"),1)  AS "temp_ma8_diff_lag8",
    /* differences – precipitation */
    ROUND("prcp_ma8" - LAG("prcp_ma8",1) OVER (ORDER BY "obs_date"),1)  AS "prcp_ma8_diff_lag1",
    ROUND("prcp_ma8" - LAG("prcp_ma8",2) OVER (ORDER BY "obs_date"),1)  AS "prcp_ma8_diff_lag2",
    ROUND("prcp_ma8" - LAG("prcp_ma8",3) OVER (ORDER BY "obs_date"),1)  AS "prcp_ma8_diff_lag3",
    ROUND("prcp_ma8" - LAG("prcp_ma8",4) OVER (ORDER BY "obs_date"),1)  AS "prcp_ma8_diff_lag4",
    ROUND("prcp_ma8" - LAG("prcp_ma8",5) OVER (ORDER BY "obs_date"),1)  AS "prcp_ma8_diff_lag5",
    ROUND("prcp_ma8" - LAG("prcp_ma8",6) OVER (ORDER BY "obs_date"),1)  AS "prcp_ma8_diff_lag6",
    ROUND("prcp_ma8" - LAG("prcp_ma8",7) OVER (ORDER BY "obs_date"),1)  AS "prcp_ma8_diff_lag7",
    ROUND("prcp_ma8" - LAG("prcp_ma8",8) OVER (ORDER BY "obs_date"),1)  AS "prcp_ma8_diff_lag8",
    /* differences – wind speed */
    ROUND("wdsp_ma8" - LAG("wdsp_ma8",1) OVER (ORDER BY "obs_date"),1)  AS "wdsp_ma8_diff_lag1",
    ROUND("wdsp_ma8" - LAG("wdsp_ma8",2) OVER (ORDER BY "obs_date"),1)  AS "wdsp_ma8_diff_lag2",
    ROUND("wdsp_ma8" - LAG("wdsp_ma8",3) OVER (ORDER BY "obs_date"),1)  AS "wdsp_ma8_diff_lag3",
    ROUND("wdsp_ma8" - LAG("wdsp_ma8",4) OVER (ORDER BY "obs_date"),1)  AS "wdsp_ma8_diff_lag4",
    ROUND("wdsp_ma8" - LAG("wdsp_ma8",5) OVER (ORDER BY "obs_date"),1)  AS "wdsp_ma8_diff_lag5",
    ROUND("wdsp_ma8" - LAG("wdsp_ma8",6) OVER (ORDER BY "obs_date"),1)  AS "wdsp_ma8_diff_lag6",
    ROUND("wdsp_ma8" - LAG("wdsp_ma8",7) OVER (ORDER BY "obs_date"),1)  AS "wdsp_ma8_diff_lag7",
    ROUND("wdsp_ma8" - LAG("wdsp_ma8",8) OVER (ORDER BY "obs_date"),1)  AS "wdsp_ma8_diff_lag8"
FROM ma
WHERE "obs_date" >= '2019-01-09'   -- first date with a full 8-day window
ORDER BY "obs_date";