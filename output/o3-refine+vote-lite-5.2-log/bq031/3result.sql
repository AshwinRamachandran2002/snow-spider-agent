-- Daily weather for Rochester (U.S.) 1 Jan – 31 Mar 2019
WITH rochester_stations AS (          -- Rochester U.S. weather stations
  SELECT DISTINCT usaf
  FROM `bigquery-public-data.noaa_gsod.stations`
  WHERE country = 'US'
    AND LOWER(name) LIKE '%rochester%'        -- Rochester, NY / MN etc.
),

raw19 AS (                           -- raw GSOD‑2019 records for those stations
  SELECT
    PARSE_DATE('%Y%m%d', CONCAT(year, LPAD(mo,2,'0'), LPAD(da,2,'0')))     AS obs_date,
    CAST(temp  AS FLOAT64)                                               AS temp_f,
    CAST(prcp  AS FLOAT64)                                               AS prcp_in,
    CAST(NULLIF(wdsp,'999.9') AS FLOAT64)                                AS wdsp_kn
  FROM `bigquery-public-data.noaa_gsod.gsod2019`
  WHERE stn IN (SELECT usaf FROM rochester_stations)
    AND CONCAT(year,LPAD(mo,2,'0'),LPAD(da,2,'0')) BETWEEN '20190101' AND '20190331'
),

daily AS (                           -- convert units & round to 1 dp
  SELECT
    obs_date,
    ROUND((temp_f-32)*5/9 ,1)                    AS temp_c,         -- °C
    ROUND(prcp_in*2.54       ,1)                 AS prcp_cm,        -- cm
    ROUND(wdsp_kn*0.514444   ,1)                 AS wind_mps        -- m s‑1
  FROM raw19
),

ma8 AS (                             -- 8‑day moving averages
  SELECT
    d.*,
    ROUND(AVG(temp_c ) OVER(w),1) AS temp_ma8,
    ROUND(AVG(prcp_cm) OVER(w),1) AS prcp_ma8,
    ROUND(AVG(wind_mps)OVER(w),1) AS wind_ma8
  FROM daily d
  WINDOW w AS (ORDER BY obs_date ROWS BETWEEN 7 PRECEDING AND CURRENT ROW)
),

lags AS (                            -- differences to lag‑1 … lag‑8 of MA series
  SELECT
    obs_date,
    temp_c, prcp_cm, wind_mps,
    temp_ma8, prcp_ma8, wind_ma8,
    ROUND(temp_ma8 - LAG(temp_ma8,1) OVER(o),1) AS temp_ma_diff1,
    ROUND(temp_ma8 - LAG(temp_ma8,2) OVER(o),1) AS temp_ma_diff2,
    ROUND(temp_ma8 - LAG(temp_ma8,3) OVER(o),1) AS temp_ma_diff3,
    ROUND(temp_ma8 - LAG(temp_ma8,4) OVER(o),1) AS temp_ma_diff4,
    ROUND(temp_ma8 - LAG(temp_ma8,5) OVER(o),1) AS temp_ma_diff5,
    ROUND(temp_ma8 - LAG(temp_ma8,6) OVER(o),1) AS temp_ma_diff6,
    ROUND(temp_ma8 - LAG(temp_ma8,7) OVER(o),1) AS temp_ma_diff7,
    ROUND(temp_ma8 - LAG(temp_ma8,8) OVER(o),1) AS temp_ma_diff8,

    ROUND(prcp_ma8 - LAG(prcp_ma8,1) OVER(o),1) AS prcp_ma_diff1,
    ROUND(prcp_ma8 - LAG(prcp_ma8,2) OVER(o),1) AS prcp_ma_diff2,
    ROUND(prcp_ma8 - LAG(prcp_ma8,3) OVER(o),1) AS prcp_ma_diff3,
    ROUND(prcp_ma8 - LAG(prcp_ma8,4) OVER(o),1) AS prcp_ma_diff4,
    ROUND(prcp_ma8 - LAG(prcp_ma8,5) OVER(o),1) AS prcp_ma_diff5,
    ROUND(prcp_ma8 - LAG(prcp_ma8,6) OVER(o),1) AS prcp_ma_diff6,
    ROUND(prcp_ma8 - LAG(prcp_ma8,7) OVER(o),1) AS prcp_ma_diff7,
    ROUND(prcp_ma8 - LAG(prcp_ma8,8) OVER(o),1) AS prcp_ma_diff8,

    ROUND(wind_ma8 - LAG(wind_ma8,1) OVER(o),1) AS wind_ma_diff1,
    ROUND(wind_ma8 - LAG(wind_ma8,2) OVER(o),1) AS wind_ma_diff2,
    ROUND(wind_ma8 - LAG(wind_ma8,3) OVER(o),1) AS wind_ma_diff3,
    ROUND(wind_ma8 - LAG(wind_ma8,4) OVER(o),1) AS wind_ma_diff4,
    ROUND(wind_ma8 - LAG(wind_ma8,5) OVER(o),1) AS wind_ma_diff5,
    ROUND(wind_ma8 - LAG(wind_ma8,6) OVER(o),1) AS wind_ma_diff6,
    ROUND(wind_ma8 - LAG(wind_ma8,7) OVER(o),1) AS wind_ma_diff7,
    ROUND(wind_ma8 - LAG(wind_ma8,8) OVER(o),1) AS wind_ma_diff8
  FROM ma8
  WINDOW o AS (ORDER BY obs_date)
)

SELECT *
FROM lags
WHERE obs_date >= '2019-01-09'               -- first day with full 8‑day window
ORDER BY obs_date;