WITH rochester_daily AS (
  /* 1.  Pull Rochester‑NY daily data (Jan 1 – Mar 31 2019) and convert units       */
  SELECT
      DATE(CAST(year AS INT64),           -- build a real DATE column
           CAST(mo   AS INT64),
           CAST(da   AS INT64))                       AS obs_date,

      /* temperature: °F ➔ °C */
      AVG( (temp - 32) * 5/9 )                         AS temp_c,

      /* precipitation: inches ➔ centimetres;  99.99 = missing  */
      AVG( CASE WHEN prcp = 99.99 THEN NULL
                ELSE prcp * 2.54 END )                AS prcp_cm,

      /* wind: knots (string) ➔ m s‑1;  999.9 = missing */
      AVG( CASE
              WHEN SAFE_CAST(wdsp AS FLOAT64) = 999.9 THEN NULL
              ELSE SAFE_CAST(wdsp AS FLOAT64) * 0.514444
          END )                                        AS wind_ms
  FROM `bigquery-public-data.noaa_gsod.gsod2019`  g
  JOIN `bigquery-public-data.noaa_gsod.stations` s
       ON g.stn  = s.usaf
      AND g.wban = s.wban
  WHERE s.state = 'NY'
    AND UPPER(s.name) LIKE '%ROCHESTER%'
    AND DATE(CAST(year AS INT64),CAST(mo AS INT64),CAST(da AS INT64))
        BETWEEN '2019-01-01' AND '2019-03-31'
  GROUP BY obs_date
),
ma8 AS (
  /* 2.  8‑day moving averages (current day + previous 7)                          */
  SELECT
      obs_date,

      ROUND(temp_c ,1)                                                    AS temp_c,
      ROUND(prcp_cm,1)                                                    AS prcp_cm,
      ROUND(wind_ms,1)                                                    AS wind_ms,

      ROUND(AVG(temp_c ) OVER(ORDER BY obs_date ROWS BETWEEN 7 PRECEDING AND CURRENT ROW),1)
                                                                          AS ma8_temp,
      ROUND(AVG(prcp_cm) OVER(ORDER BY obs_date ROWS BETWEEN 7 PRECEDING AND CURRENT ROW),1)
                                                                          AS ma8_prcp,
      ROUND(AVG(wind_ms) OVER(ORDER BY obs_date ROWS BETWEEN 7 PRECEDING AND CURRENT ROW),1)
                                                                          AS ma8_wind
  FROM rochester_daily
)
SELECT
    obs_date                                                           AS date,

    /* daily values ---------------------------------------------------*/
    temp_c,
    prcp_cm,
    wind_ms,

    /* 8‑day moving avgs ----------------------------------------------*/
    ma8_temp,
    ma8_prcp,
    ma8_wind,

    /* temperature MA differences (lags 1‑8) --------------------------*/
    ROUND(ma8_temp - LAG(ma8_temp,1) OVER(ORDER BY obs_date),1)  AS temp_ma_diff_lag1,
    ROUND(ma8_temp - LAG(ma8_temp,2) OVER(ORDER BY obs_date),1)  AS temp_ma_diff_lag2,
    ROUND(ma8_temp - LAG(ma8_temp,3) OVER(ORDER BY obs_date),1)  AS temp_ma_diff_lag3,
    ROUND(ma8_temp - LAG(ma8_temp,4) OVER(ORDER BY obs_date),1)  AS temp_ma_diff_lag4,
    ROUND(ma8_temp - LAG(ma8_temp,5) OVER(ORDER BY obs_date),1)  AS temp_ma_diff_lag5,
    ROUND(ma8_temp - LAG(ma8_temp,6) OVER(ORDER BY obs_date),1)  AS temp_ma_diff_lag6,
    ROUND(ma8_temp - LAG(ma8_temp,7) OVER(ORDER BY obs_date),1)  AS temp_ma_diff_lag7,
    ROUND(ma8_temp - LAG(ma8_temp,8) OVER(ORDER BY obs_date),1)  AS temp_ma_diff_lag8,

    /* precipitation MA differences -----------------------------------*/
    ROUND(ma8_prcp - LAG(ma8_prcp,1) OVER(ORDER BY obs_date),1) AS prcp_ma_diff_lag1,
    ROUND(ma8_prcp - LAG(ma8_prcp,2) OVER(ORDER BY obs_date),1) AS prcp_ma_diff_lag2,
    ROUND(ma8_prcp - LAG(ma8_prcp,3) OVER(ORDER BY obs_date),1) AS prcp_ma_diff_lag3,
    ROUND(ma8_prcp - LAG(ma8_prcp,4) OVER(ORDER BY obs_date),1) AS prcp_ma_diff_lag4,
    ROUND(ma8_prcp - LAG(ma8_prcp,5) OVER(ORDER BY obs_date),1) AS prcp_ma_diff_lag5,
    ROUND(ma8_prcp - LAG(ma8_prcp,6) OVER(ORDER BY obs_date),1) AS prcp_ma_diff_lag6,
    ROUND(ma8_prcp - LAG(ma8_prcp,7) OVER(ORDER BY obs_date),1) AS prcp_ma_diff_lag7,
    ROUND(ma8_prcp - LAG(ma8_prcp,8) OVER(ORDER BY obs_date),1) AS prcp_ma_diff_lag8,

    /* wind‑speed MA differences --------------------------------------*/
    ROUND(ma8_wind - LAG(ma8_wind,1) OVER(ORDER BY obs_date),1) AS wind_ma_diff_lag1,
    ROUND(ma8_wind - LAG(ma8_wind,2) OVER(ORDER BY obs_date),1) AS wind_ma_diff_lag2,
    ROUND(ma8_wind - LAG(ma8_wind,3) OVER(ORDER BY obs_date),1) AS wind_ma_diff_lag3,
    ROUND(ma8_wind - LAG(ma8_wind,4) OVER(ORDER BY obs_date),1) AS wind_ma_diff_lag4,
    ROUND(ma8_wind - LAG(ma8_wind,5) OVER(ORDER BY obs_date),1) AS wind_ma_diff_lag5,
    ROUND(ma8_wind - LAG(ma8_wind,6) OVER(ORDER BY obs_date),1) AS wind_ma_diff_lag6,
    ROUND(ma8_wind - LAG(ma8_wind,7) OVER(ORDER BY obs_date),1) AS wind_ma_diff_lag7,
    ROUND(ma8_wind - LAG(ma8_wind,8) OVER(ORDER BY obs_date),1) AS wind_ma_diff_lag8
FROM ma8
WHERE obs_date >= '2019-01-09'          -- first day with a full 8‑day window
ORDER BY obs_date;