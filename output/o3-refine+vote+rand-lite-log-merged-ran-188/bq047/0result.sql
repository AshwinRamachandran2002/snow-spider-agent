-- Relationship between NYC 311 complaint types and temperature (2008-2017)

WITH temp AS (
  -- 1) Daily mean of LaGuardia (725030) & JFK (744860) temps
  SELECT
    PARSE_DATE('%Y%m%d', CONCAT(year, LPAD(mo,2,'0'), LPAD(da,2,'0'))) AS day,
    AVG(temp) AS mean_temp_f
  FROM `bigquery-public-data.noaa_gsod.gsod20*`
  WHERE _TABLE_SUFFIX BETWEEN '08' AND '17'          -- 2008-2017 inclusive
    AND stn IN ('725030','744860')                   -- LGA & JFK
    AND temp <> 9999.9                               -- exclude missing values
  GROUP BY day
),

complaints AS (
  -- 2) 311 complaints for the same 10-year span
  SELECT
    DATE(created_date) AS day,
    complaint_type
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE EXTRACT(YEAR FROM created_date) BETWEEN 2008 AND 2017
),

daily AS (
  -- 3) Daily counts by complaint type joined to temperature
  SELECT
    t.day,
    c.complaint_type,
    COUNT(*) AS cnt,
    SUM(COUNT(*)) OVER (PARTITION BY t.day) AS day_total,
    t.mean_temp_f
  FROM temp AS t
  JOIN complaints AS c USING (day)
  GROUP BY t.day, c.complaint_type, t.mean_temp_f
),

summary AS (
  -- 4) Correlations and totals per complaint type
  SELECT
    complaint_type,
    SUM(cnt) AS total_complaints,
    COUNT(DISTINCT day) AS valid_days,
    CORR(mean_temp_f, cnt)              AS corr_cnt,
    CORR(mean_temp_f, cnt / day_total)  AS corr_pct
  FROM daily
  GROUP BY complaint_type
  HAVING total_complaints > 5000        -- only common complaints
     AND ABS(corr_cnt) > 0.5            -- strong correlation threshold
)

-- 5) Final report
SELECT
  complaint_type,
  total_complaints,
  valid_days,
  ROUND(corr_cnt, 4) AS corr_cnt,
  ROUND(corr_pct, 4) AS corr_pct
FROM summary
ORDER BY ABS(corr_cnt) DESC;