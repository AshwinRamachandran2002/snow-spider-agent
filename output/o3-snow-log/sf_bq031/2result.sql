/*  Daily Rochester (USAF 725290 / WBAN 14768) weather, 1 Jan → 31 Mar 2019
    – ° C, cm, m s-¹ conversions
    – 8-day moving averages (MA-8, current-day + 7 prior days)
    – Differences between today’s MA-8 and the MA-8 from 1-8 days ago
    Values rounded to a single decimal; output begins 9 Jan 2019
*/

WITH daily AS (      ----------------------------------------------------------
    SELECT
        TO_DATE("year"||'-'||"mo"||'-'||"da", 'YYYY-MM-DD')                    AS obs_date,
        ROUND( ( "temp" - 32 ) * 5/9 , 1)                                      AS temp_c,     -- °F → °C
        ROUND(   "prcp" * 2.54        , 1)                                      AS prcp_cm,    -- inch → cm
        ROUND(   "wdsp" * 0.514444    , 1)                                      AS wdsp_ms     -- kt   → m s-¹
    FROM  NOAA_DATA.NOAA_GSOD."GSOD2019"
    WHERE "stn"  = '725290'            -- Greater Rochester International
      AND "wban" = '14768'
      AND "year" = '2019'
      AND "mo"   IN ('01','02','03')   -- Jan-Mar only
),

ma AS (           --------------------------------------------------------------
    SELECT
        obs_date,
        temp_c,
        prcp_cm,
        wdsp_ms,
        ROUND(
            AVG(temp_c)  OVER (ORDER BY obs_date ROWS BETWEEN 7 PRECEDING AND CURRENT ROW), 1
        ) AS temp_ma8,
        ROUND(
            AVG(prcp_cm) OVER (ORDER BY obs_date ROWS BETWEEN 7 PRECEDING AND CURRENT ROW), 1
        ) AS prcp_ma8,
        ROUND(
            AVG(wdsp_ms) OVER (ORDER BY obs_date ROWS BETWEEN 7 PRECEDING AND CURRENT ROW), 1
        ) AS wdsp_ma8
    FROM daily
)

SELECT
    obs_date                                                 AS "date",
    temp_c, prcp_cm, wdsp_ms,
    temp_ma8, prcp_ma8, wdsp_ma8,

    /* temperature MA-8 lag differences */
    ROUND(temp_ma8 - LAG(temp_ma8, 1) OVER (ORDER BY obs_date), 1)  AS temp_diff_lag1,
    ROUND(temp_ma8 - LAG(temp_ma8, 2) OVER (ORDER BY obs_date), 1)  AS temp_diff_lag2,
    ROUND(temp_ma8 - LAG(temp_ma8, 3) OVER (ORDER BY obs_date), 1)  AS temp_diff_lag3,
    ROUND(temp_ma8 - LAG(temp_ma8, 4) OVER (ORDER BY obs_date), 1)  AS temp_diff_lag4,
    ROUND(temp_ma8 - LAG(temp_ma8, 5) OVER (ORDER BY obs_date), 1)  AS temp_diff_lag5,
    ROUND(temp_ma8 - LAG(temp_ma8, 6) OVER (ORDER BY obs_date), 1)  AS temp_diff_lag6,
    ROUND(temp_ma8 - LAG(temp_ma8, 7) OVER (ORDER BY obs_date), 1)  AS temp_diff_lag7,
    ROUND(temp_ma8 - LAG(temp_ma8, 8) OVER (ORDER BY obs_date), 1)  AS temp_diff_lag8,

    /* precipitation MA-8 lag differences */
    ROUND(prcp_ma8 - LAG(prcp_ma8, 1) OVER (ORDER BY obs_date), 1)  AS prcp_diff_lag1,
    ROUND(prcp_ma8 - LAG(prcp_ma8, 2) OVER (ORDER BY obs_date), 1)  AS prcp_diff_lag2,
    ROUND(prcp_ma8 - LAG(prcp_ma8, 3) OVER (ORDER BY obs_date), 1)  AS prcp_diff_lag3,
    ROUND(prcp_ma8 - LAG(prcp_ma8, 4) OVER (ORDER BY obs_date), 1)  AS prcp_diff_lag4,
    ROUND(prcp_ma8 - LAG(prcp_ma8, 5) OVER (ORDER BY obs_date), 1)  AS prcp_diff_lag5,
    ROUND(prcp_ma8 - LAG(prcp_ma8, 6) OVER (ORDER BY obs_date), 1)  AS prcp_diff_lag6,
    ROUND(prcp_ma8 - LAG(prcp_ma8, 7) OVER (ORDER BY obs_date), 1)  AS prcp_diff_lag7,
    ROUND(prcp_ma8 - LAG(prcp_ma8, 8) OVER (ORDER BY obs_date), 1)  AS prcp_diff_lag8,

    /* wind-speed MA-8 lag differences */
    ROUND(wdsp_ma8 - LAG(wdsp_ma8, 1) OVER (ORDER BY obs_date), 1)  AS wdsp_diff_lag1,
    ROUND(wdsp_ma8 - LAG(wdsp_ma8, 2) OVER (ORDER BY obs_date), 1)  AS wdsp_diff_lag2,
    ROUND(wdsp_ma8 - LAG(wdsp_ma8, 3) OVER (ORDER BY obs_date), 1)  AS wdsp_diff_lag3,
    ROUND(wdsp_ma8 - LAG(wdsp_ma8, 4) OVER (ORDER BY obs_date), 1)  AS wdsp_diff_lag4,
    ROUND(wdsp_ma8 - LAG(wdsp_ma8, 5) OVER (ORDER BY obs_date), 1)  AS wdsp_diff_lag5,
    ROUND(wdsp_ma8 - LAG(wdsp_ma8, 6) OVER (ORDER BY obs_date), 1)  AS wdsp_diff_lag6,
    ROUND(wdsp_ma8 - LAG(wdsp_ma8, 7) OVER (ORDER BY obs_date), 1)  AS wdsp_diff_lag7,
    ROUND(wdsp_ma8 - LAG(wdsp_ma8, 8) OVER (ORDER BY obs_date), 1)  AS wdsp_diff_lag8

FROM ma
WHERE obs_date BETWEEN '2019-01-09' AND '2019-03-31'  -- first full MA-8 window
ORDER BY obs_date;