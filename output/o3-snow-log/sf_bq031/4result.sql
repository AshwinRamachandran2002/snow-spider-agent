/*  Daily Rochester (NY) weather: 2019-01-01 … 2019-03-31
    – metric values
    – 8-day moving averages
    – lag-difference columns (1 … 8 days)
*/
WITH daily AS (
    /* convert GSOD units to metric ---------------------------------------- */
    SELECT
        TO_DATE("year"||"mo"||"da",'YYYYMMDD')                               AS "date",
        ROUND( ( "temp" - 32 ) * 5/9 , 1)                                    AS "temp_c",     -- °C
        ROUND( CASE WHEN "prcp" >= 99 THEN NULL 
                    ELSE "prcp"*2.54 END , 1)                               AS "prcp_cm",     -- cm
        ROUND( TRY_TO_NUMBER("wdsp") * 0.44704 , 1)                          AS "wind_mps"     -- m s-1
    FROM   NOAA_DATA.NOAA_GSOD."GSOD2019"
    WHERE  "stn"  = '725290'          -- Greater Rochester International Airport
      AND  "wban" = '14768'
      AND  "mo" IN ('01','02','03')   -- Jan-Mar 2019
), ma AS (
    /* 8-day (current + 7 prior days) moving averages ---------------------- */
    SELECT
        d.*,
        ROUND( AVG("temp_c")  OVER(ORDER BY "date" ROWS 7 PRECEDING), 1) AS "temp_ma8",
        ROUND( AVG("prcp_cm") OVER(ORDER BY "date" ROWS 7 PRECEDING), 1) AS "prcp_ma8",
        ROUND( AVG("wind_mps")OVER(ORDER BY "date" ROWS 7 PRECEDING), 1) AS "wind_ma8"
    FROM daily d
)
SELECT
    "date",
    "temp_c","prcp_cm","wind_mps",
    /* 8-day moving averages */
    "temp_ma8","prcp_ma8","wind_ma8",
    /* lag-diffs: moving-average(today) − moving-average(n-days-ago) -------- */
    /* temperature */
    ROUND("temp_ma8" - LAG("temp_ma8",1) OVER(ORDER BY "date"),1) AS "temp_ma8_lag1",
    ROUND("temp_ma8" - LAG("temp_ma8",2) OVER(ORDER BY "date"),1) AS "temp_ma8_lag2",
    ROUND("temp_ma8" - LAG("temp_ma8",3) OVER(ORDER BY "date"),1) AS "temp_ma8_lag3",
    ROUND("temp_ma8" - LAG("temp_ma8",4) OVER(ORDER BY "date"),1) AS "temp_ma8_lag4",
    ROUND("temp_ma8" - LAG("temp_ma8",5) OVER(ORDER BY "date"),1) AS "temp_ma8_lag5",
    ROUND("temp_ma8" - LAG("temp_ma8",6) OVER(ORDER BY "date"),1) AS "temp_ma8_lag6",
    ROUND("temp_ma8" - LAG("temp_ma8",7) OVER(ORDER BY "date"),1) AS "temp_ma8_lag7",
    ROUND("temp_ma8" - LAG("temp_ma8",8) OVER(ORDER BY "date"),1) AS "temp_ma8_lag8",
    /* precipitation */
    ROUND("prcp_ma8" - LAG("prcp_ma8",1) OVER(ORDER BY "date"),1) AS "prcp_ma8_lag1",
    ROUND("prcp_ma8" - LAG("prcp_ma8",2) OVER(ORDER BY "date"),1) AS "prcp_ma8_lag2",
    ROUND("prcp_ma8" - LAG("prcp_ma8",3) OVER(ORDER BY "date"),1) AS "prcp_ma8_lag3",
    ROUND("prcp_ma8" - LAG("prcp_ma8",4) OVER(ORDER BY "date"),1) AS "prcp_ma8_lag4",
    ROUND("prcp_ma8" - LAG("prcp_ma8",5) OVER(ORDER BY "date"),1) AS "prcp_ma8_lag5",
    ROUND("prcp_ma8" - LAG("prcp_ma8",6) OVER(ORDER BY "date"),1) AS "prcp_ma8_lag6",
    ROUND("prcp_ma8" - LAG("prcp_ma8",7) OVER(ORDER BY "date"),1) AS "prcp_ma8_lag7",
    ROUND("prcp_ma8" - LAG("prcp_ma8",8) OVER(ORDER BY "date"),1) AS "prcp_ma8_lag8",
    /* wind speed */
    ROUND("wind_ma8" - LAG("wind_ma8",1) OVER(ORDER BY "date"),1) AS "wind_ma8_lag1",
    ROUND("wind_ma8" - LAG("wind_ma8",2) OVER(ORDER BY "date"),1) AS "wind_ma8_lag2",
    ROUND("wind_ma8" - LAG("wind_ma8",3) OVER(ORDER BY "date"),1) AS "wind_ma8_lag3",
    ROUND("wind_ma8" - LAG("wind_ma8",4) OVER(ORDER BY "date"),1) AS "wind_ma8_lag4",
    ROUND("wind_ma8" - LAG("wind_ma8",5) OVER(ORDER BY "date"),1) AS "wind_ma8_lag5",
    ROUND("wind_ma8" - LAG("wind_ma8",6) OVER(ORDER BY "date"),1) AS "wind_ma8_lag6",
    ROUND("wind_ma8" - LAG("wind_ma8",7) OVER(ORDER BY "date"),1) AS "wind_ma8_lag7",
    ROUND("wind_ma8" - LAG("wind_ma8",8) OVER(ORDER BY "date"),1) AS "wind_ma8_lag8"
FROM   ma
WHERE  "date" BETWEEN '2019-01-09' AND '2019-03-31'   -- first day with full 8-day window
ORDER  BY "date";