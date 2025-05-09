/*  Relationship between weather (LaGuardia + JFK mean daily temperature)
    and NYC 311 complaint types, 2008‑2017                                           */

WITH temp AS (   -- 1.  Daily mean temperature for LGA (725030) & JFK (744860)
  SELECT
    PARSE_DATE('%Y%m%d', CONCAT(year, LPAD(mo,2,'0'), LPAD(da,2,'0'))) AS day,
    AVG(temp) AS mean_temp_f          -- exclude bogus 9999.9 readings
  FROM `bigquery-public-data.noaa_gsod.gsod*`
  WHERE _TABLE_SUFFIX BETWEEN '2008' AND '2017'
    AND stn IN ('725030','744860')
    AND temp < 9999.9
  GROUP BY day
),

daily_311 AS (   -- 2.  Daily counts of each complaint type
  SELECT
    DATE(created_date) AS day,
    complaint_type,
    COUNT(*) AS daily_cnt
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE created_date BETWEEN '2008-01-01' AND '2017-12-31'
  GROUP BY day, complaint_type
),

type_totals AS ( -- 3.  Complaint types with > 5 000 records in period
  SELECT
    complaint_type,
    SUM(daily_cnt) AS total_cnt
  FROM daily_311
  GROUP BY complaint_type
  HAVING total_cnt > 5000
),

joined AS (      -- 4.  Calendar of all valid‑temperature days × eligible types
  SELECT
    t.day,
    tt.complaint_type,
    tt.total_cnt,
    t.mean_temp_f,
    COALESCE(d.daily_cnt,0)                         AS daily_cnt,
    COALESCE(d.daily_cnt,0)/tt.total_cnt            AS daily_pct
  FROM temp            t
  CROSS JOIN type_totals tt
  LEFT JOIN daily_311  d
         ON d.day = t.day
        AND d.complaint_type = tt.complaint_type
),

stats AS (       -- 5.  Correlations per complaint type
  SELECT
    complaint_type,
    MAX(total_cnt)                                           AS total_complaints,
    COUNT(*)                                                 AS days_with_temp,
    CORR(mean_temp_f, daily_cnt)                             AS corr_cnt,
    CORR(mean_temp_f, daily_pct)                             AS corr_pct
  FROM joined
  GROUP BY complaint_type
)

-- 6.  Final result: strong correlations |corr_cnt| > 0.5
SELECT
  complaint_type,
  total_complaints,
  days_with_temp,
  ROUND(corr_cnt,  4) AS corr_temp_daily_count,
  ROUND(corr_pct,  4) AS corr_temp_daily_percentage
FROM stats
WHERE ABS(corr_cnt) > 0.5
ORDER BY ABS(corr_cnt) DESC, complaint_type;