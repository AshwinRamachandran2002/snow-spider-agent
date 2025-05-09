/*  Daily Rochester-MN weather (01-Jan-2019 → 31-Mar-2019)
    – °C / cm / m s⁻¹
    – 8-day moving averages
    – lag-1 … lag-8 differences of the moving averages               */

WITH base AS (
  SELECT
    DATE(CONCAT(year,'-',mo,'-',da))                                        AS obs_date,
    ROUND( (temp - 32) * 5/9            , 1)                                AS temp_c,
    ROUND( prcp * 2.54                  , 1)                                AS prcp_cm,
    ROUND( CAST(wdsp AS FLOAT64) * 0.514444 , 1)                            AS wind_m_s
  FROM `bigquery-public-data.noaa_gsod.gsod2019`
  WHERE stn  = '726440'                    -- Rochester-MN  (International Airport)
    AND wban = '14925'
    AND DATE(CONCAT(year,'-',mo,'-',da)) BETWEEN '2019-01-01' AND '2019-03-31'
),
ma AS (
  SELECT
    obs_date,
    temp_c,
    prcp_cm,
    wind_m_s,
    ROUND(AVG(temp_c)  OVER (ORDER BY obs_date ROWS BETWEEN 7 PRECEDING AND CURRENT ROW),1) AS ma8_temp_c,
    ROUND(AVG(prcp_cm) OVER (ORDER BY obs_date ROWS BETWEEN 7 PRECEDING AND CURRENT ROW),1) AS ma8_prcp_cm,
    ROUND(AVG(wind_m_s)OVER (ORDER BY obs_date ROWS BETWEEN 7 PRECEDING AND CURRENT ROW),1) AS ma8_wind_m_s
  FROM base
)
SELECT
  obs_date,

  /* temperature ---------------------------------------------------- */
  temp_c,
  ma8_temp_c,
  ROUND(ma8_temp_c - LAG(ma8_temp_c,1) OVER (ORDER BY obs_date),1) AS temp_ma_diff1,
  ROUND(ma8_temp_c - LAG(ma8_temp_c,2) OVER (ORDER BY obs_date),1) AS temp_ma_diff2,
  ROUND(ma8_temp_c - LAG(ma8_temp_c,3) OVER (ORDER BY obs_date),1) AS temp_ma_diff3,
  ROUND(ma8_temp_c - LAG(ma8_temp_c,4) OVER (ORDER BY obs_date),1) AS temp_ma_diff4,
  ROUND(ma8_temp_c - LAG(ma8_temp_c,5) OVER (ORDER BY obs_date),1) AS temp_ma_diff5,
  ROUND(ma8_temp_c - LAG(ma8_temp_c,6) OVER (ORDER BY obs_date),1) AS temp_ma_diff6,
  ROUND(ma8_temp_c - LAG(ma8_temp_c,7) OVER (ORDER BY obs_date),1) AS temp_ma_diff7,
  ROUND(ma8_temp_c - LAG(ma8_temp_c,8) OVER (ORDER BY obs_date),1) AS temp_ma_diff8,

  /* precipitation -------------------------------------------------- */
  prcp_cm,
  ma8_prcp_cm,
  ROUND(ma8_prcp_cm - LAG(ma8_prcp_cm,1) OVER (ORDER BY obs_date),1) AS prcp_ma_diff1,
  ROUND(ma8_prcp_cm - LAG(ma8_prcp_cm,2) OVER (ORDER BY obs_date),1) AS prcp_ma_diff2,
  ROUND(ma8_prcp_cm - LAG(ma8_prcp_cm,3) OVER (ORDER BY obs_date),1) AS prcp_ma_diff3,
  ROUND(ma8_prcp_cm - LAG(ma8_prcp_cm,4) OVER (ORDER BY obs_date),1) AS prcp_ma_diff4,
  ROUND(ma8_prcp_cm - LAG(ma8_prcp_cm,5) OVER (ORDER BY obs_date),1) AS prcp_ma_diff5,
  ROUND(ma8_prcp_cm - LAG(ma8_prcp_cm,6) OVER (ORDER BY obs_date),1) AS prcp_ma_diff6,
  ROUND(ma8_prcp_cm - LAG(ma8_prcp_cm,7) OVER (ORDER BY obs_date),1) AS prcp_ma_diff7,
  ROUND(ma8_prcp_cm - LAG(ma8_prcp_cm,8) OVER (ORDER BY obs_date),1) AS prcp_ma_diff8,

  /* wind ----------------------------------------------------------- */
  wind_m_s,
  ma8_wind_m_s,
  ROUND(ma8_wind_m_s - LAG(ma8_wind_m_s,1) OVER (ORDER BY obs_date),1) AS wind_ma_diff1,
  ROUND(ma8_wind_m_s - LAG(ma8_wind_m_s,2) OVER (ORDER BY obs_date),1) AS wind_ma_diff2,
  ROUND(ma8_wind_m_s - LAG(ma8_wind_m_s,3) OVER (ORDER BY obs_date),1) AS wind_ma_diff3,
  ROUND(ma8_wind_m_s - LAG(ma8_wind_m_s,4) OVER (ORDER BY obs_date),1) AS wind_ma_diff4,
  ROUND(ma8_wind_m_s - LAG(ma8_wind_m_s,5) OVER (ORDER BY obs_date),1) AS wind_ma_diff5,
  ROUND(ma8_wind_m_s - LAG(ma8_wind_m_s,6) OVER (ORDER BY obs_date),1) AS wind_ma_diff6,
  ROUND(ma8_wind_m_s - LAG(ma8_wind_m_s,7) OVER (ORDER BY obs_date),1) AS wind_ma_diff7,
  ROUND(ma8_wind_m_s - LAG(ma8_wind_m_s,8) OVER (ORDER BY obs_date),1) AS wind_ma_diff8

FROM ma
WHERE obs_date >= '2019-01-09'   -- first day with a full 8-day window
ORDER BY obs_date;