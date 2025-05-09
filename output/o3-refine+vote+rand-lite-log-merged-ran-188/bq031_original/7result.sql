/*  Rochester (NY) daily weather – Jan 1 – Mar 31 2019
    · GSOD variables converted to SI units
    · 8‑day moving‑average (current day + 7 previous)
    · Differences between today’s MA and MA from 1‑8 days ago
*/

WITH station_rochester AS (          -- every Rochester‑NY station id
  SELECT DISTINCT usaf
  FROM   `bigquery-public-data.noaa_gsod.stations`
  WHERE  state = 'NY'
    AND  LOWER(name) LIKE '%rochester%'
),
raw AS (                              -- GSOD 2019 rows for those stations
  SELECT
    PARSE_DATE('%Y%m%d', CONCAT(year, LPAD(mo,2,'0'), LPAD(da,2,'0'))) AS dt,
    SAFE_CAST(temp AS FLOAT64)  AS temp_f,
    SAFE_CAST(prcp AS FLOAT64)  AS prcp_in,
    SAFE_CAST(wdsp AS FLOAT64)  AS wdsp_mph
  FROM   `bigquery-public-data.noaa_gsod.gsod2019` g
  JOIN   station_rochester s
  ON     g.stn = s.usaf
  WHERE  PARSE_DATE('%Y%m%d', CONCAT(year, LPAD(mo,2,'0'), LPAD(da,2,'0')))
         BETWEEN DATE '2019-01-01' AND DATE '2019-03-31'
),
conv AS (                             -- convert to SI and set missing to NULL
  SELECT
    dt,
    ROUND((temp_f - 32) * 5/9, 1)                    AS temp_c,
    ROUND(CASE WHEN prcp_in = 99.99 THEN NULL
               ELSE prcp_in * 2.54 END, 1)           AS prcp_cm,
    ROUND(CASE WHEN wdsp_mph = 999.9 THEN NULL
               ELSE wdsp_mph * 0.44704 END, 1)       AS wind_ms
  FROM raw
),
calendar AS (                         -- ensure a row for every calendar day
  SELECT dt
  FROM UNNEST(GENERATE_DATE_ARRAY('2019-01-01','2019-03-31')) AS dt
),
daily AS (                            -- merge weather onto full calendar
  SELECT
    c.dt,
    d.temp_c,
    d.prcp_cm,
    d.wind_ms
  FROM calendar c
  LEFT JOIN conv d USING (dt)
),
ma AS (                               -- 8‑day moving averages
  SELECT
    *,
    ROUND(AVG(temp_c)  OVER w, 1) AS temp_ma8,
    ROUND(AVG(prcp_cm) OVER w, 1) AS prcp_ma8,
    ROUND(AVG(wind_ms) OVER w, 1) AS wind_ma8
  FROM daily
  WINDOW w AS (ORDER BY dt ROWS BETWEEN 7 PRECEDING AND CURRENT ROW)
)
SELECT
  dt                                                   AS date,
  temp_c, prcp_cm, wind_ms,
  temp_ma8, prcp_ma8, wind_ma8,

  -- MA‑8 lag‑day differences (temperature)
  ROUND(temp_ma8 - LAG(temp_ma8,1) OVER (ORDER BY dt),1) AS temp_ma8_diff_lag1,
  ROUND(temp_ma8 - LAG(temp_ma8,2) OVER (ORDER BY dt),1) AS temp_ma8_diff_lag2,
  ROUND(temp_ma8 - LAG(temp_ma8,3) OVER (ORDER BY dt),1) AS temp_ma8_diff_lag3,
  ROUND(temp_ma8 - LAG(temp_ma8,4) OVER (ORDER BY dt),1) AS temp_ma8_diff_lag4,
  ROUND(temp_ma8 - LAG(temp_ma8,5) OVER (ORDER BY dt),1) AS temp_ma8_diff_lag5,
  ROUND(temp_ma8 - LAG(temp_ma8,6) OVER (ORDER BY dt),1) AS temp_ma8_diff_lag6,
  ROUND(temp_ma8 - LAG(temp_ma8,7) OVER (ORDER BY dt),1) AS temp_ma8_diff_lag7,
  ROUND(temp_ma8 - LAG(temp_ma8,8) OVER (ORDER BY dt),1) AS temp_ma8_diff_lag8,

  -- precipitation
  ROUND(prcp_ma8 - LAG(prcp_ma8,1) OVER (ORDER BY dt),1) AS prcp_ma8_diff_lag1,
  ROUND(prcp_ma8 - LAG(prcp_ma8,2) OVER (ORDER BY dt),1) AS prcp_ma8_diff_lag2,
  ROUND(prcp_ma8 - LAG(prcp_ma8,3) OVER (ORDER BY dt),1) AS prcp_ma8_diff_lag3,
  ROUND(prcp_ma8 - LAG(prcp_ma8,4) OVER (ORDER BY dt),1) AS prcp_ma8_diff_lag4,
  ROUND(prcp_ma8 - LAG(prcp_ma8,5) OVER (ORDER BY dt),1) AS prcp_ma8_diff_lag5,
  ROUND(prcp_ma8 - LAG(prcp_ma8,6) OVER (ORDER BY dt),1) AS prcp_ma8_diff_lag6,
  ROUND(prcp_ma8 - LAG(prcp_ma8,7) OVER (ORDER BY dt),1) AS prcp_ma8_diff_lag7,
  ROUND(prcp_ma8 - LAG(prcp_ma8,8) OVER (ORDER BY dt),1) AS prcp_ma8_diff_lag8,

  -- wind speed
  ROUND(wind_ma8 - LAG(wind_ma8,1) OVER (ORDER BY dt),1) AS wind_ma8_diff_lag1,
  ROUND(wind_ma8 - LAG(wind_ma8,2) OVER (ORDER BY dt),1) AS wind_ma8_diff_lag2,
  ROUND(wind_ma8 - LAG(wind_ma8,3) OVER (ORDER BY dt),1) AS wind_ma8_diff_lag3,
  ROUND(wind_ma8 - LAG(wind_ma8,4) OVER (ORDER BY dt),1) AS wind_ma8_diff_lag4,
  ROUND(wind_ma8 - LAG(wind_ma8,5) OVER (ORDER BY dt),1) AS wind_ma8_diff_lag5,
  ROUND(wind_ma8 - LAG(wind_ma8,6) OVER (ORDER BY dt),1) AS wind_ma8_diff_lag6,
  ROUND(wind_ma8 - LAG(wind_ma8,7) OVER (ORDER BY dt),1) AS wind_ma8_diff_lag7,
  ROUND(wind_ma8 - LAG(wind_ma8,8) OVER (ORDER BY dt),1) AS wind_ma8_diff_lag8

FROM ma
WHERE dt >= DATE '2019-01-09'         -- first date with full 8‑day window
ORDER BY dt;