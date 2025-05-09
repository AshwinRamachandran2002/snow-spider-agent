-- Daily Rochester-NY weather (USAF 725290 / WBAN 14768)
-- 8-day moving averages and 1-8-day lag-diffs
WITH base AS (
  SELECT
    DATE(CONCAT(year,'-',mo,'-',da))                          AS ymd,
    -- convert °F→°C, in→cm, kt→m s-1 ; turn GSOD missing sentinels into NULLs
    CASE WHEN temp IS NULL OR temp = 9999.9 THEN NULL
         ELSE ROUND( (temp-32)*5/9 ,1) END                    AS temp_c,
    CASE WHEN prcp IS NULL OR prcp = 99.99 THEN NULL
         ELSE ROUND( prcp*2.54 ,1) END                        AS prcp_cm,
    CASE WHEN SAFE_CAST(wdsp AS FLOAT64) IS NULL
          OR SAFE_CAST(wdsp AS FLOAT64) = 999.9 THEN NULL
         ELSE ROUND( SAFE_CAST(wdsp AS FLOAT64)*0.514444 ,1) END
                                                             AS wdsp_mps
  FROM `bigquery-public-data.noaa_gsod.gsod2019`
  WHERE stn  = '725290'
    AND wban = '14768'
    AND DATE(CONCAT(year,'-',mo,'-',da))
        BETWEEN '2019-01-01' AND '2019-03-31'
),
ma AS (
  SELECT
    *,
    -- 8-day (current day + 7 previous) moving averages
    ROUND(AVG(temp_c ) OVER (ORDER BY ymd ROWS BETWEEN 7 PRECEDING AND CURRENT ROW),1) AS temp_ma8,
    ROUND(AVG(prcp_cm) OVER (ORDER BY ymd ROWS BETWEEN 7 PRECEDING AND CURRENT ROW),1) AS prcp_ma8,
    ROUND(AVG(wdsp_mps) OVER (ORDER BY ymd ROWS BETWEEN 7 PRECEDING AND CURRENT ROW),1) AS wdsp_ma8
  FROM base
),
diffs AS (
  SELECT
    *,
    -- temperature MA differences
    ROUND(temp_ma8 - LAG(temp_ma8,1) OVER(ORDER BY ymd),1) AS temp_ma8_diff_lag1,
    ROUND(temp_ma8 - LAG(temp_ma8,2) OVER(ORDER BY ymd),1) AS temp_ma8_diff_lag2,
    ROUND(temp_ma8 - LAG(temp_ma8,3) OVER(ORDER BY ymd),1) AS temp_ma8_diff_lag3,
    ROUND(temp_ma8 - LAG(temp_ma8,4) OVER(ORDER BY ymd),1) AS temp_ma8_diff_lag4,
    ROUND(temp_ma8 - LAG(temp_ma8,5) OVER(ORDER BY ymd),1) AS temp_ma8_diff_lag5,
    ROUND(temp_ma8 - LAG(temp_ma8,6) OVER(ORDER BY ymd),1) AS temp_ma8_diff_lag6,
    ROUND(temp_ma8 - LAG(temp_ma8,7) OVER(ORDER BY ymd),1) AS temp_ma8_diff_lag7,
    ROUND(temp_ma8 - LAG(temp_ma8,8) OVER(ORDER BY ymd),1) AS temp_ma8_diff_lag8,

    -- precipitation MA differences
    ROUND(prcp_ma8 - LAG(prcp_ma8,1) OVER(ORDER BY ymd),1) AS prcp_ma8_diff_lag1,
    ROUND(prcp_ma8 - LAG(prcp_ma8,2) OVER(ORDER BY ymd),1) AS prcp_ma8_diff_lag2,
    ROUND(prcp_ma8 - LAG(prcp_ma8,3) OVER(ORDER BY ymd),1) AS prcp_ma8_diff_lag3,
    ROUND(prcp_ma8 - LAG(prcp_ma8,4) OVER(ORDER BY ymd),1) AS prcp_ma8_diff_lag4,
    ROUND(prcp_ma8 - LAG(prcp_ma8,5) OVER(ORDER BY ymd),1) AS prcp_ma8_diff_lag5,
    ROUND(prcp_ma8 - LAG(prcp_ma8,6) OVER(ORDER BY ymd),1) AS prcp_ma8_diff_lag6,
    ROUND(prcp_ma8 - LAG(prcp_ma8,7) OVER(ORDER BY ymd),1) AS prcp_ma8_diff_lag7,
    ROUND(prcp_ma8 - LAG(prcp_ma8,8) OVER(ORDER BY ymd),1) AS prcp_ma8_diff_lag8,

    -- wind-speed MA differences
    ROUND(wdsp_ma8 - LAG(wdsp_ma8,1) OVER(ORDER BY ymd),1) AS wdsp_ma8_diff_lag1,
    ROUND(wdsp_ma8 - LAG(wdsp_ma8,2) OVER(ORDER BY ymd),1) AS wdsp_ma8_diff_lag2,
    ROUND(wdsp_ma8 - LAG(wdsp_ma8,3) OVER(ORDER BY ymd),1) AS wdsp_ma8_diff_lag3,
    ROUND(wdsp_ma8 - LAG(wdsp_ma8,4) OVER(ORDER BY ymd),1) AS wdsp_ma8_diff_lag4,
    ROUND(wdsp_ma8 - LAG(wdsp_ma8,5) OVER(ORDER BY ymd),1) AS wdsp_ma8_diff_lag5,
    ROUND(wdsp_ma8 - LAG(wdsp_ma8,6) OVER(ORDER BY ymd),1) AS wdsp_ma8_diff_lag6,
    ROUND(wdsp_ma8 - LAG(wdsp_ma8,7) OVER(ORDER BY ymd),1) AS wdsp_ma8_diff_lag7,
    ROUND(wdsp_ma8 - LAG(wdsp_ma8,8) OVER(ORDER BY ymd),1) AS wdsp_ma8_diff_lag8
  FROM ma
)
SELECT
  *
FROM diffs
WHERE ymd >= '2019-01-09'          -- first day with a full 8-day window
ORDER BY ymd;