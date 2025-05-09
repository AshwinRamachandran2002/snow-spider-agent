-- Daily weather for Rochester-NY (USAF 725290) with 8-day moving averages
-- and lag-1 … lag-8 differences for 1 Jan – 31 Mar 2019
WITH daily AS (
  SELECT
    DATE(CONCAT(year, '-', mo, '-', da)) AS obs_date,
    -- °F → °C (exclude missing 9999.9)
    CASE WHEN temp < 9999 THEN ROUND((temp - 32) * 5 / 9, 1) END       AS temp_c,
    -- inches → cm (exclude missing 99.99)
    CASE WHEN prcp < 99.99 THEN ROUND(prcp * 2.54, 1) END              AS prcp_cm,
    -- knots → m s⁻¹ (exclude 999.9)
    CASE
      WHEN SAFE_CAST(wdsp AS FLOAT64) < 999
      THEN ROUND(SAFE_CAST(wdsp AS FLOAT64) * 0.514444, 1)
    END                                                               AS wind_ms
  FROM `bigquery-public-data.noaa_gsod.gsod2019`
  WHERE stn = '725290'                           -- Greater Rochester Intl
    AND CONCAT(mo, da) BETWEEN '0101' AND '0331' -- Jan–Mar 2019
),
ma AS (                                           -- 8-day moving averages
  SELECT
    obs_date,
    temp_c,
    prcp_cm,
    wind_ms,
    ROUND(AVG(temp_c ) OVER win, 1) AS ma8_temp,
    ROUND(AVG(prcp_cm) OVER win, 1) AS ma8_prcp,
    ROUND(AVG(wind_ms) OVER win, 1) AS ma8_wind
  FROM daily
  WINDOW win AS (ORDER BY obs_date ROWS BETWEEN 7 PRECEDING AND CURRENT ROW)
)
SELECT
  obs_date,
  temp_c, prcp_cm, wind_ms,
  ma8_temp, ma8_prcp, ma8_wind,

  -- temperature differences
  ROUND(ma8_temp - LAG(ma8_temp, 1) OVER(ORDER BY obs_date), 1) AS temp_diff_lag1,
  ROUND(ma8_temp - LAG(ma8_temp, 2) OVER(ORDER BY obs_date), 1) AS temp_diff_lag2,
  ROUND(ma8_temp - LAG(ma8_temp, 3) OVER(ORDER BY obs_date), 1) AS temp_diff_lag3,
  ROUND(ma8_temp - LAG(ma8_temp, 4) OVER(ORDER BY obs_date), 1) AS temp_diff_lag4,
  ROUND(ma8_temp - LAG(ma8_temp, 5) OVER(ORDER BY obs_date), 1) AS temp_diff_lag5,
  ROUND(ma8_temp - LAG(ma8_temp, 6) OVER(ORDER BY obs_date), 1) AS temp_diff_lag6,
  ROUND(ma8_temp - LAG(ma8_temp, 7) OVER(ORDER BY obs_date), 1) AS temp_diff_lag7,
  ROUND(ma8_temp - LAG(ma8_temp, 8) OVER(ORDER BY obs_date), 1) AS temp_diff_lag8,

  -- precipitation differences
  ROUND(ma8_prcp - LAG(ma8_prcp, 1) OVER(ORDER BY obs_date), 1) AS prcp_diff_lag1,
  ROUND(ma8_prcp - LAG(ma8_prcp, 2) OVER(ORDER BY obs_date), 1) AS prcp_diff_lag2,
  ROUND(ma8_prcp - LAG(ma8_prcp, 3) OVER(ORDER BY obs_date), 1) AS prcp_diff_lag3,
  ROUND(ma8_prcp - LAG(ma8_prcp, 4) OVER(ORDER BY obs_date), 1) AS prcp_diff_lag4,
  ROUND(ma8_prcp - LAG(ma8_prcp, 5) OVER(ORDER BY obs_date), 1) AS prcp_diff_lag5,
  ROUND(ma8_prcp - LAG(ma8_prcp, 6) OVER(ORDER BY obs_date), 1) AS prcp_diff_lag6,
  ROUND(ma8_prcp - LAG(ma8_prcp, 7) OVER(ORDER BY obs_date), 1) AS prcp_diff_lag7,
  ROUND(ma8_prcp - LAG(ma8_prcp, 8) OVER(ORDER BY obs_date), 1) AS prcp_diff_lag8,

  -- wind-speed differences
  ROUND(ma8_wind - LAG(ma8_wind, 1) OVER(ORDER BY obs_date), 1) AS wind_diff_lag1,
  ROUND(ma8_wind - LAG(ma8_wind, 2) OVER(ORDER BY obs_date), 1) AS wind_diff_lag2,
  ROUND(ma8_wind - LAG(ma8_wind, 3) OVER(ORDER BY obs_date), 1) AS wind_diff_lag3,
  ROUND(ma8_wind - LAG(ma8_wind, 4) OVER(ORDER BY obs_date), 1) AS wind_diff_lag4,
  ROUND(ma8_wind - LAG(ma8_wind, 5) OVER(ORDER BY obs_date), 1) AS wind_diff_lag5,
  ROUND(ma8_wind - LAG(ma8_wind, 6) OVER(ORDER BY obs_date), 1) AS wind_diff_lag6,
  ROUND(ma8_wind - LAG(ma8_wind, 7) OVER(ORDER BY obs_date), 1) AS wind_diff_lag7,
  ROUND(ma8_wind - LAG(ma8_wind, 8) OVER(ORDER BY obs_date), 1) AS wind_diff_lag8
FROM ma
WHERE obs_date >= '2019-01-09' -- first row with a full 8-day window
ORDER BY obs_date;