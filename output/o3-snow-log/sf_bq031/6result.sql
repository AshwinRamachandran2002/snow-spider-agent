/*  Daily weather, 8-day moving averages, and lag-1 … lag-8 MA differences
    for the Rochester-NY station (STN = 725290) from 01-Jan-2019 to 31-Mar-2019. */

WITH base AS (   -- daily values converted to metric units
    SELECT
        TO_DATE("year"||'-'||"mo"||'-'||"da")                          AS "date",
        ROUND( ( "temp" - 32 ) * 5/9 , 1)                              AS "temp_c",      -- °C
        ROUND(   "prcp" / 10        , 1)                              AS "prcp_cm",     -- cm
        ROUND( TRY_TO_DOUBLE("wdsp") * 0.514444 , 1)                  AS "wind_mps"     -- m s-¹
    FROM  NOAA_DATA.NOAA_GSOD."GSOD2019"
    WHERE "stn" = '725290'
      AND TO_DATE("year"||'-'||"mo"||'-'||"da")
          BETWEEN '2019-01-01' AND '2019-03-31'
),

ma8 AS (        -- 8-day (current day + 7 prior days) moving averages
    SELECT
        b.*,
        ROUND(AVG(b."temp_c")  OVER (ORDER BY b."date"
                                     ROWS BETWEEN 7 PRECEDING AND CURRENT ROW), 1) AS "temp_ma8",
        ROUND(AVG(b."prcp_cm") OVER (ORDER BY b."date"
                                     ROWS BETWEEN 7 PRECEDING AND CURRENT ROW), 1) AS "prcp_ma8",
        ROUND(AVG(b."wind_mps")OVER (ORDER BY b."date"
                                     ROWS BETWEEN 7 PRECEDING AND CURRENT ROW), 1) AS "wind_ma8"
    FROM base b
)

SELECT
    "date",
    /* daily metrics */
    "temp_c",
    "prcp_cm",
    "wind_mps",

    /* 8-day moving averages */
    "temp_ma8",
    "prcp_ma8",
    "wind_ma8",

    /* differences between today’s MA and MA’s from the previous 1 … 8 days */
    ROUND("temp_ma8" - LAG("temp_ma8", 1) OVER (ORDER BY "date"), 1) AS "temp_ma8_diff_lag1",
    ROUND("temp_ma8" - LAG("temp_ma8", 2) OVER (ORDER BY "date"), 1) AS "temp_ma8_diff_lag2",
    ROUND("temp_ma8" - LAG("temp_ma8", 3) OVER (ORDER BY "date"), 1) AS "temp_ma8_diff_lag3",
    ROUND("temp_ma8" - LAG("temp_ma8", 4) OVER (ORDER BY "date"), 1) AS "temp_ma8_diff_lag4",
    ROUND("temp_ma8" - LAG("temp_ma8", 5) OVER (ORDER BY "date"), 1) AS "temp_ma8_diff_lag5",
    ROUND("temp_ma8" - LAG("temp_ma8", 6) OVER (ORDER BY "date"), 1) AS "temp_ma8_diff_lag6",
    ROUND("temp_ma8" - LAG("temp_ma8", 7) OVER (ORDER BY "date"), 1) AS "temp_ma8_diff_lag7",
    ROUND("temp_ma8" - LAG("temp_ma8", 8) OVER (ORDER BY "date"), 1) AS "temp_ma8_diff_lag8",

    ROUND("prcp_ma8" - LAG("prcp_ma8", 1) OVER (ORDER BY "date"), 1) AS "prcp_ma8_diff_lag1",
    ROUND("prcp_ma8" - LAG("prcp_ma8", 2) OVER (ORDER BY "date"), 1) AS "prcp_ma8_diff_lag2",
    ROUND("prcp_ma8" - LAG("prcp_ma8", 3) OVER (ORDER BY "date"), 1) AS "prcp_ma8_diff_lag3",
    ROUND("prcp_ma8" - LAG("prcp_ma8", 4) OVER (ORDER BY "date"), 1) AS "prcp_ma8_diff_lag4",
    ROUND("prcp_ma8" - LAG("prcp_ma8", 5) OVER (ORDER BY "date"), 1) AS "prcp_ma8_diff_lag5",
    ROUND("prcp_ma8" - LAG("prcp_ma8", 6) OVER (ORDER BY "date"), 1) AS "prcp_ma8_diff_lag6",
    ROUND("prcp_ma8" - LAG("prcp_ma8", 7) OVER (ORDER BY "date"), 1) AS "prcp_ma8_diff_lag7",
    ROUND("prcp_ma8" - LAG("prcp_ma8", 8) OVER (ORDER BY "date"), 1) AS "prcp_ma8_diff_lag8",

    ROUND("wind_ma8" - LAG("wind_ma8", 1) OVER (ORDER BY "date"), 1) AS "wind_ma8_diff_lag1",
    ROUND("wind_ma8" - LAG("wind_ma8", 2) OVER (ORDER BY "date"), 1) AS "wind_ma8_diff_lag2",
    ROUND("wind_ma8" - LAG("wind_ma8", 3) OVER (ORDER BY "date"), 1) AS "wind_ma8_diff_lag3",
    ROUND("wind_ma8" - LAG("wind_ma8", 4) OVER (ORDER BY "date"), 1) AS "wind_ma8_diff_lag4",
    ROUND("wind_ma8" - LAG("wind_ma8", 5) OVER (ORDER BY "date"), 1) AS "wind_ma8_diff_lag5",
    ROUND("wind_ma8" - LAG("wind_ma8", 6) OVER (ORDER BY "date"), 1) AS "wind_ma8_diff_lag6",
    ROUND("wind_ma8" - LAG("wind_ma8", 7) OVER (ORDER BY "date"), 1) AS "wind_ma8_diff_lag7",
    ROUND("wind_ma8" - LAG("wind_ma8", 8) OVER (ORDER BY "date"), 1) AS "wind_ma8_diff_lag8"

FROM ma8
WHERE "date" BETWEEN '2019-01-09' AND '2019-03-31'   -- first day with a full 8-day window
ORDER BY "date";