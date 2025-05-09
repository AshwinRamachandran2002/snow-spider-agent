-- Rochester (NY) daily weather, 8‑day moving averages and lag‑differences
WITH rochester_stations AS (
  -- pick GSOD stations located in Rochester, New York
  SELECT
    TRIM(usaf)   AS usaf,
    TRIM(wban)   AS wban
  FROM `bigquery-public-data.noaa_gsod.stations`
  WHERE state = 'NY'
    AND REGEXP_CONTAINS(UPPER(TRIM(name)), r'ROCHESTER')
),

daily_raw AS (
  -- daily mean values for each variable (ignore GSOD missing sentinels)
  SELECT
    DATE(CONCAT(year,'-',mo,'-',da))                        AS day,
    AVG(NULLIF(temp , 9999.9))                              AS temp_f,        -- °F
    AVG(CASE WHEN prcp != 99.99 THEN prcp END)              AS prcp_in,       -- inch
    AVG(CAST(NULLIF(wdsp,'999.9') AS FLOAT64))              AS wdsp_kt        -- knot
  FROM `bigquery-public-data.noaa_gsod.gsod2019` g
  JOIN rochester_stations s
    ON g.stn  = s.usaf
   AND g.wban = s.wban
  WHERE DATE(CONCAT(year,'-',mo,'-',da)) BETWEEN '2019-01-01' AND '2019-03-31'
  GROUP BY day
),

daily_converted AS (
  SELECT
    day,
    -- convert to requested units
    (temp_f - 32) * 5/9                     AS temp_c,      -- °C
    prcp_in * 2.54                          AS prcp_cm,     -- cm
    wdsp_kt * 0.514444                      AS wdsp_mps     -- m s‑1
  FROM daily_raw
),

ma AS (
  -- 8‑day moving averages (current day + previous 7)
  SELECT
    day,
    ROUND(temp_c ,1)                                                               AS temp_c,
    ROUND(prcp_cm,1)                                                               AS prcp_cm,
    ROUND(wdsp_mps,1)                                                              AS wdsp_mps,
    ROUND(AVG(temp_c ) OVER (ORDER BY day ROWS BETWEEN 7 PRECEDING AND CURRENT ROW),1) AS ma_temp_c,
    ROUND(AVG(prcp_cm) OVER (ORDER BY day ROWS BETWEEN 7 PRECEDING AND CURRENT ROW),1) AS ma_prcp_cm,
    ROUND(AVG(wdsp_mps)OVER (ORDER BY day ROWS BETWEEN 7 PRECEDING AND CURRENT ROW),1) AS ma_wdsp_mps
  FROM daily_converted
),

final AS (
  SELECT
    day,
    temp_c,  prcp_cm,  wdsp_mps,
    ma_temp_c, ma_prcp_cm, ma_wdsp_mps,

    -- temperature MA differences
    ROUND(ma_temp_c - LAG(ma_temp_c,1) OVER(ORDER BY day),1) AS temp_ma_diff_lag1,
    ROUND(ma_temp_c - LAG(ma_temp_c,2) OVER(ORDER BY day),1) AS temp_ma_diff_lag2,
    ROUND(ma_temp_c - LAG(ma_temp_c,3) OVER(ORDER BY day),1) AS temp_ma_diff_lag3,
    ROUND(ma_temp_c - LAG(ma_temp_c,4) OVER(ORDER BY day),1) AS temp_ma_diff_lag4,
    ROUND(ma_temp_c - LAG(ma_temp_c,5) OVER(ORDER BY day),1) AS temp_ma_diff_lag5,
    ROUND(ma_temp_c - LAG(ma_temp_c,6) OVER(ORDER BY day),1) AS temp_ma_diff_lag6,
    ROUND(ma_temp_c - LAG(ma_temp_c,7) OVER(ORDER BY day),1) AS temp_ma_diff_lag7,
    ROUND(ma_temp_c - LAG(ma_temp_c,8) OVER(ORDER BY day),1) AS temp_ma_diff_lag8,

    -- precipitation MA differences
    ROUND(ma_prcp_cm - LAG(ma_prcp_cm,1) OVER(ORDER BY day),1) AS prcp_ma_diff_lag1,
    ROUND(ma_prcp_cm - LAG(ma_prcp_cm,2) OVER(ORDER BY day),1) AS prcp_ma_diff_lag2,
    ROUND(ma_prcp_cm - LAG(ma_prcp_cm,3) OVER(ORDER BY day),1) AS prcp_ma_diff_lag3,
    ROUND(ma_prcp_cm - LAG(ma_prcp_cm,4) OVER(ORDER BY day),1) AS prcp_ma_diff_lag4,
    ROUND(ma_prcp_cm - LAG(ma_prcp_cm,5) OVER(ORDER BY day),1) AS prcp_ma_diff_lag5,
    ROUND(ma_prcp_cm - LAG(ma_prcp_cm,6) OVER(ORDER BY day),1) AS prcp_ma_diff_lag6,
    ROUND(ma_prcp_cm - LAG(ma_prcp_cm,7) OVER(ORDER BY day),1) AS prcp_ma_diff_lag7,
    ROUND(ma_prcp_cm - LAG(ma_prcp_cm,8) OVER(ORDER BY day),1) AS prcp_ma_diff_lag8,

    -- wind‑speed MA differences
    ROUND(ma_wdsp_mps - LAG(ma_wdsp_mps,1) OVER(ORDER BY day),1) AS wind_ma_diff_lag1,
    ROUND(ma_wdsp_mps - LAG(ma_wdsp_mps,2) OVER(ORDER BY day),1) AS wind_ma_diff_lag2,
    ROUND(ma_wdsp_mps - LAG(ma_wdsp_mps,3) OVER(ORDER BY day),1) AS wind_ma_diff_lag3,
    ROUND(ma_wdsp_mps - LAG(ma_wdsp_mps,4) OVER(ORDER BY day),1) AS wind_ma_diff_lag4,
    ROUND(ma_wdsp_mps - LAG(ma_wdsp_mps,5) OVER(ORDER BY day),1) AS wind_ma_diff_lag5,
    ROUND(ma_wdsp_mps - LAG(ma_wdsp_mps,6) OVER(ORDER BY day),1) AS wind_ma_diff_lag6,
    ROUND(ma_wdsp_mps - LAG(ma_wdsp_mps,7) OVER(ORDER BY day),1) AS wind_ma_diff_lag7,
    ROUND(ma_wdsp_mps - LAG(ma_wdsp_mps,8) OVER(ORDER BY day),1) AS wind_ma_diff_lag8
  FROM ma
)

SELECT *
FROM final
WHERE day BETWEEN '2019-01-09' AND '2019-03-31'   -- first day with full 8‑day window
ORDER BY day;