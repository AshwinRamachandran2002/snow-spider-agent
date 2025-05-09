-- Correlate NYC daily temperature (LGA+JFK average) with 311 complaint activity, 2008‑2017
WITH daily_temp AS (                    -- mean temperature per day
  SELECT
    DATE(CONCAT(year,'-',mo,'-',da)) AS day ,
    AVG(temp)                       AS avg_temp
  FROM `bigquery-public-data.noaa_gsod.gsod*`
  WHERE _TABLE_SUFFIX BETWEEN '2008' AND '2017'
    AND stn IN ('725030','744860')          -- LaGuardia & JFK
    AND temp < 9999.9                       -- exclude sentinel
  GROUP BY day
),
daily_totals AS (                         -- total 311 complaints per day
  SELECT
    DATE(created_date) AS day ,
    COUNT(*)           AS total_daily
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE DATE(created_date) BETWEEN '2008-01-01' AND '2017-12-31'
  GROUP BY day
),
big_types AS (                            -- complaint types with >5 000 cases
  SELECT
    complaint_type ,
    COUNT(*) AS total_complaints
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE DATE(created_date) BETWEEN '2008-01-01' AND '2017-12-31'
  GROUP BY complaint_type
  HAVING total_complaints > 5000
),
daily_type AS (                           -- daily counts for those types
  SELECT
    DATE(created_date) AS day ,
    complaint_type ,
    COUNT(*)           AS type_daily
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE DATE(created_date) BETWEEN '2008-01-01' AND '2017-12-31'
    AND complaint_type IN (SELECT complaint_type FROM big_types)
  GROUP BY day , complaint_type
),
corr_prep AS (                            -- grid of day × complaint_type
  SELECT
    bt.complaint_type ,
    dt.day ,
    dt.avg_temp ,
    COALESCE(dy.type_daily , 0) AS type_daily ,
    tot.total_daily
  FROM big_types      AS bt
  CROSS JOIN daily_temp AS dt
  JOIN  daily_totals  AS tot ON tot.day = dt.day
  LEFT JOIN daily_type AS dy
         ON dy.day = dt.day
        AND dy.complaint_type = bt.complaint_type
)
SELECT
  complaint_type ,
  SUM(type_daily)                                      AS total_complaints ,
  COUNT(*)                                             AS total_days ,
  ROUND(CORR(avg_temp , type_daily)                           ,4) AS corr_cnt ,
  ROUND(CORR(avg_temp , SAFE_DIVIDE(type_daily , total_daily)),4) AS corr_pct
FROM corr_prep
GROUP BY complaint_type
HAVING GREATEST(
         ABS(CORR(avg_temp , type_daily)),
         ABS(CORR(avg_temp , SAFE_DIVIDE(type_daily , total_daily)))
       ) > 0.5                     -- keep only strong correlations
ORDER BY complaint_type;