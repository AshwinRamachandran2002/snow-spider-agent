/*  Daily Rochester (NY) weather, 2019-01-01 … 2019-03-31
    – Temperature (°C), precipitation (cm), wind-speed (m s-1)
    – 8-day moving averages
    – Lag-difference of the moving averages (1- to 8-day)

    Station: 725290 / 14768  (Greater Rochester Intl. Airport)
*/
WITH base AS (   -- convert units & clean obvious “missing” codes
  SELECT
    DATE(CONCAT(year,'-',mo,'-',da))                                       AS obs_date,

    -- temperature °F → °C
    ROUND( (temp-32)*5/9 , 1)                                              AS temp_c,

    -- precipitation  inches → cm   (99.99 = missing)
    ROUND( CASE WHEN prcp = 99.99 THEN NULL ELSE prcp*2.54 END , 1)        AS prcp_cm,

    -- wind-speed  knots → m s-1     (999.9 = missing)
    ROUND(
      CASE 
        WHEN SAFE_CAST(wdsp AS FLOAT64) = 999.9 THEN NULL
        ELSE SAFE_CAST(wdsp AS FLOAT64)*0.514444 
      END , 1)                                                             AS wind_ms
  FROM `bigquery-public-data.noaa_gsod.gsod2019`
  WHERE stn  = '725290'        -- Rochester-NY USAF code
    AND wban = '14768'         -- Rochester-NY WBAN code
    AND DATE(CONCAT(year,'-',mo,'-',da)) BETWEEN '2019-01-01' AND '2019-03-31'
),

ma AS (   -- 8-day (current-day + 7 prior) moving averages
  SELECT
    obs_date,
    temp_c,
    prcp_cm,
    wind_ms,

    ROUND(AVG(temp_c)  OVER (ORDER BY obs_date ROWS BETWEEN 7 PRECEDING AND CURRENT ROW),1) AS temp8_avg,
    ROUND(AVG(prcp_cm) OVER (ORDER BY obs_date ROWS BETWEEN 7 PRECEDING AND CURRENT ROW),1) AS prcp8_avg,
    ROUND(AVG(wind_ms) OVER (ORDER BY obs_date ROWS BETWEEN 7 PRECEDING AND CURRENT ROW),1) AS wind8_avg
  FROM base
),

diffs AS (   -- lag-differences of the moving averages
  SELECT
    obs_date,

    /* ------- daily values ------- */
    temp_c,
    prcp_cm,
    wind_ms,

    /* ------- 8-day moving averages ------- */
    temp8_avg,
    prcp8_avg,
    wind8_avg,

    /* ------- temperature – lag differences ------- */
    ROUND(temp8_avg - LAG(temp8_avg,1) OVER (ORDER BY obs_date),1) AS temp_diff_lag1,
    ROUND(temp8_avg - LAG(temp8_avg,2) OVER (ORDER BY obs_date),1) AS temp_diff_lag2,
    ROUND(temp8_avg - LAG(temp8_avg,3) OVER (ORDER BY obs_date),1) AS temp_diff_lag3,
    ROUND(temp8_avg - LAG(temp8_avg,4) OVER (ORDER BY obs_date),1) AS temp_diff_lag4,
    ROUND(temp8_avg - LAG(temp8_avg,5) OVER (ORDER BY obs_date),1) AS temp_diff_lag5,
    ROUND(temp8_avg - LAG(temp8_avg,6) OVER (ORDER BY obs_date),1) AS temp_diff_lag6,
    ROUND(temp8_avg - LAG(temp8_avg,7) OVER (ORDER BY obs_date),1) AS temp_diff_lag7,
    ROUND(temp8_avg - LAG(temp8_avg,8) OVER (ORDER BY obs_date),1) AS temp_diff_lag8,

    /* ------- precipitation – lag differences ------- */
    ROUND(prcp8_avg - LAG(prcp8_avg,1) OVER (ORDER BY obs_date),1) AS prcp_diff_lag1,
    ROUND(prcp8_avg - LAG(prcp8_avg,2) OVER (ORDER BY obs_date),1) AS prcp_diff_lag2,
    ROUND(prcp8_avg - LAG(prcp8_avg,3) OVER (ORDER BY obs_date),1) AS prcp_diff_lag3,
    ROUND(prcp8_avg - LAG(prcp8_avg,4) OVER (ORDER BY obs_date),1) AS prcp_diff_lag4,
    ROUND(prcp8_avg - LAG(prcp8_avg,5) OVER (ORDER BY obs_date),1) AS prcp_diff_lag5,
    ROUND(prcp8_avg - LAG(prcp8_avg,6) OVER (ORDER BY obs_date),1) AS prcp_diff_lag6,
    ROUND(prcp8_avg - LAG(prcp8_avg,7) OVER (ORDER BY obs_date),1) AS prcp_diff_lag7,
    ROUND(prcp8_avg - LAG(prcp8_avg,8) OVER (ORDER BY obs_date),1) AS prcp_diff_lag8,

    /* ------- wind speed – lag differences ------- */
    ROUND(wind8_avg - LAG(wind8_avg,1) OVER (ORDER BY obs_date),1) AS wind_diff_lag1,
    ROUND(wind8_avg - LAG(wind8_avg,2) OVER (ORDER BY obs_date),1) AS wind_diff_lag2,
    ROUND(wind8_avg - LAG(wind8_avg,3) OVER (ORDER BY obs_date),1) AS wind_diff_lag3,
    ROUND(wind8_avg - LAG(wind8_avg,4) OVER (ORDER BY obs_date),1) AS wind_diff_lag4,
    ROUND(wind8_avg - LAG(wind8_avg,5) OVER (ORDER BY obs_date),1) AS wind_diff_lag5,
    ROUND(wind8_avg - LAG(wind8_avg,6) OVER (ORDER BY obs_date),1) AS wind_diff_lag6,
    ROUND(wind8_avg - LAG(wind8_avg,7) OVER (ORDER BY obs_date),1) AS wind_diff_lag7,
    ROUND(wind8_avg - LAG(wind8_avg,8) OVER (ORDER BY obs_date),1) AS wind_diff_lag8
  FROM ma
)

SELECT *
FROM diffs
WHERE obs_date >= '2019-01-09'      -- first day with a complete 8-day window
ORDER BY obs_date;