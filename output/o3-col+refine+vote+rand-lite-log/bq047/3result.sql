/*  Relationship between daily temperature (LGA & JFK) and 311 complaint types, 2008-2017  */
WITH temp AS (      -- daily mean °F from LaGuardia (725030) + JFK (744860)
  SELECT
    DATE(CAST(year AS INT64), CAST(mo AS INT64), CAST(da AS INT64)) AS d,
    AVG(temp) AS temp_f
  FROM `bigquery-public-data.noaa_gsod.gsod*`
  WHERE _TABLE_SUFFIX BETWEEN '2008' AND '2017'          -- 10-year window
    AND stn IN ('725030','744860')                       -- LGA & JFK
    AND temp <> 9999.9                                   -- exclude invalid
  GROUP BY d
),
complaints AS (      -- daily counts per complaint type
  SELECT
    DATE(created_date) AS d,
    complaint_type,
    COUNT(*) AS cnt
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE EXTRACT(YEAR FROM created_date) BETWEEN 2008 AND 2017
  GROUP BY d, complaint_type
),
daily_tot AS (       -- total 311 complaints per day
  SELECT d, SUM(cnt) AS day_total
  FROM complaints
  GROUP BY d
),
stats AS (           -- compute correlations
  SELECT
    c.complaint_type,
    SUM(c.cnt)                       AS total_complaints,
    COUNT(*)                         AS days_w_temp,
    CORR(t.temp_f , c.cnt)           AS corr_cnt,
    CORR(t.temp_f , c.cnt / dt.day_total) AS corr_pct
  FROM complaints c
  JOIN temp      t  ON t.d  = c.d
  JOIN daily_tot dt ON dt.d = c.d
  GROUP BY c.complaint_type
  HAVING total_complaints > 5000          -- only frequent types
     AND ABS(corr_cnt) > 0.5              -- strong correlation
)
SELECT
  complaint_type,
  total_complaints,
  days_w_temp,
  ROUND(corr_cnt ,4) AS corr_count,
  ROUND(corr_pct ,4) AS corr_pct_of_day
FROM stats
ORDER BY ABS(corr_cnt) DESC;