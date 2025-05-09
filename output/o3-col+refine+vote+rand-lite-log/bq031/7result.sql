/*  Daily Rochester (NY, USA) weather – 8-day moving averages & lag
    (Jan-01-2019 – Mar-31-2019)                                              */
WITH rochester_station AS (     -- choose the latest-ending Rochester-NY site
  SELECT
    usaf ,
    wban
  FROM `bigquery-public-data.noaa_gsod.stations`
  WHERE country = 'US'
    AND state   = 'NY'
    AND REGEXP_CONTAINS(UPPER(name), r'ROCHESTER')
  ORDER BY CAST(`end` AS INT64) DESC         -- `end` is a reserved word
  LIMIT 1
),
daily_raw AS (                  -- raw 2019 records for that station
  SELECT
    PARSE_DATE('%Y-%m-%d',
      FORMAT('%04d-%02d-%02d',
             CAST(year AS INT64),
             CAST(mo   AS INT64),
             CAST(da   AS INT64)))                       AS day,
    CAST(temp AS FLOAT64)            AS temp_f ,
    CAST(prcp AS FLOAT64)            AS prcp_in ,
    SAFE_CAST(wdsp AS FLOAT64)       AS wdsp_kn
  FROM `bigquery-public-data.noaa_gsod.gsod2019` g
  JOIN rochester_station s
    ON g.stn  = s.usaf
   AND g.wban = s.wban
  WHERE CONCAT(year,'-',mo,'-',da) BETWEEN '2019-01-01' AND '2019-03-31'
),
daily AS (                      -- convert units & replace sentinel values
  SELECT
    day,
    ROUND( (temp_f - 32) * 5/9 , 1)                                       AS temp_c ,
    ROUND( IF(prcp_in = 99.99, NULL, prcp_in * 2.54) , 1)                 AS prcp_cm ,
    ROUND( IF(wdsp_kn = 999.9, NULL, wdsp_kn * 0.514444) , 1)             AS wind_mps
  FROM daily_raw
),
ma AS (                          -- 8-day moving averages
  SELECT
    day,
    temp_c ,
    prcp_cm ,
    wind_mps ,
    AVG(temp_c )  OVER w AS temp_ma8 ,
    AVG(prcp_cm)  OVER w AS prcp_ma8 ,
    AVG(wind_mps) OVER w AS wind_ma8
  FROM daily
  WINDOW w AS (ORDER BY day ROWS BETWEEN 7 PRECEDING AND CURRENT ROW)
),
final AS (                       -- lag-difference calculations & rounding
  SELECT
    day,
    temp_c , prcp_cm , wind_mps ,

    ROUND(temp_ma8 ,1) AS temp_ma8 ,
    ROUND(prcp_ma8 ,1) AS prcp_ma8 ,
    ROUND(wind_ma8 ,1) AS wind_ma8 ,

    -- temp moving-average differences (lag1…lag8)
    ROUND(temp_ma8 - LAG(temp_ma8 ,1) OVER(ORDER BY day),1) AS temp_ma8_diff_lag1,
    ROUND(temp_ma8 - LAG(temp_ma8 ,2) OVER(ORDER BY day),1) AS temp_ma8_diff_lag2,
    ROUND(temp_ma8 - LAG(temp_ma8 ,3) OVER(ORDER BY day),1) AS temp_ma8_diff_lag3,
    ROUND(temp_ma8 - LAG(temp_ma8 ,4) OVER(ORDER BY day),1) AS temp_ma8_diff_lag4,
    ROUND(temp_ma8 - LAG(temp_ma8 ,5) OVER(ORDER BY day),1) AS temp_ma8_diff_lag5,
    ROUND(temp_ma8 - LAG(temp_ma8 ,6) OVER(ORDER BY day),1) AS temp_ma8_diff_lag6,
    ROUND(temp_ma8 - LAG(temp_ma8 ,7) OVER(ORDER BY day),1) AS temp_ma8_diff_lag7,
    ROUND(temp_ma8 - LAG(temp_ma8 ,8) OVER(ORDER BY day),1) AS temp_ma8_diff_lag8,

    -- precipitation moving-average differences
    ROUND(prcp_ma8 - LAG(prcp_ma8 ,1) OVER(ORDER BY day),1) AS prcp_ma8_diff_lag1,
    ROUND(prcp_ma8 - LAG(prcp_ma8 ,2) OVER(ORDER BY day),1) AS prcp_ma8_diff_lag2,
    ROUND(prcp_ma8 - LAG(prcp_ma8 ,3) OVER(ORDER BY day),1) AS prcp_ma8_diff_lag3,
    ROUND(prcp_ma8 - LAG(prcp_ma8 ,4) OVER(ORDER BY day),1) AS prcp_ma8_diff_lag4,
    ROUND(prcp_ma8 - LAG(prcp_ma8 ,5) OVER(ORDER BY day),1) AS prcp_ma8_diff_lag5,
    ROUND(prcp_ma8 - LAG(prcp_ma8 ,6) OVER(ORDER BY day),1) AS prcp_ma8_diff_lag6,
    ROUND(prcp_ma8 - LAG(prcp_ma8 ,7) OVER(ORDER BY day),1) AS prcp_ma8_diff_lag7,
    ROUND(prcp_ma8 - LAG(prcp_ma8 ,8) OVER(ORDER BY day),1) AS prcp_ma8_diff_lag8,

    -- wind moving-average differences
    ROUND(wind_ma8 - LAG(wind_ma8 ,1) OVER(ORDER BY day),1) AS wind_ma8_diff_lag1,
    ROUND(wind_ma8 - LAG(wind_ma8 ,2) OVER(ORDER BY day),1) AS wind_ma8_diff_lag2,
    ROUND(wind_ma8 - LAG(wind_ma8 ,3) OVER(ORDER BY day),1) AS wind_ma8_diff_lag3,
    ROUND(wind_ma8 - LAG(wind_ma8 ,4) OVER(ORDER BY day),1) AS wind_ma8_diff_lag4,
    ROUND(wind_ma8 - LAG(wind_ma8 ,5) OVER(ORDER BY day),1) AS wind_ma8_diff_lag5,
    ROUND(wind_ma8 - LAG(wind_ma8 ,6) OVER(ORDER BY day),1) AS wind_ma8_diff_lag6,
    ROUND(wind_ma8 - LAG(wind_ma8 ,7) OVER(ORDER BY day),1) AS wind_ma8_diff_lag7,
    ROUND(wind_ma8 - LAG(wind_ma8 ,8) OVER(ORDER BY day),1) AS wind_ma8_diff_lag8
  FROM ma
)
SELECT *
FROM final
WHERE day >= '2019-01-09'          -- first date with complete 8-day window
ORDER BY day;