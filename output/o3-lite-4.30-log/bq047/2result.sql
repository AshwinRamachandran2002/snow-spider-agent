WITH daily_temp AS (
  /* average daily temperature from LaGuardia (725030) and JFK (744860) */
  SELECT
    DATE(CAST(year AS INT64), CAST(mo AS INT64), CAST(da AS INT64)) AS day,
    AVG(temp)                                                     AS avg_temp
  FROM `bigquery-public-data.noaa_gsod.gsod20*`
  WHERE _TABLE_SUFFIX IN ('08','09','10','11','12','13','14','15','16','17')   -- 2008‑2017
    AND stn IN ('725030','744860')                                             -- LGA & JFK
    AND temp <> 9999.9                                                         -- valid temps
  GROUP BY day
),
daily_complaints AS (
  /* daily 311 counts per complaint type */
  SELECT
    DATE(created_date) AS day,
    complaint_type,
    COUNT(*)           AS cnt
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE DATE(created_date) BETWEEN '2008-01-01' AND '2017-12-31'
  GROUP BY day, complaint_type
),
total_per_day AS (
  /* total 311 complaints each day (needed for percentage) */
  SELECT
    day,
    SUM(cnt) AS total_cnt_day
  FROM daily_complaints
  GROUP BY day
),
joined AS (
  /* join temperature with complaint counts & compute daily percentage */
  SELECT
    dc.complaint_type,
    dc.day,
    dc.cnt,
    SAFE_DIVIDE(dc.cnt, tpd.total_cnt_day) AS pct_of_day,
    dt.avg_temp
  FROM daily_temp       dt
  JOIN daily_complaints dc  ON dt.day = dc.day
  JOIN total_per_day    tpd ON dt.day = tpd.day
),
totals AS (
  /* keep complaint types that occur > 5 000 times */
  SELECT
    complaint_type,
    SUM(cnt) AS total_complaints
  FROM joined
  GROUP BY complaint_type
  HAVING total_complaints > 5000
),
stats AS (
  /* compute correlations for each selected complaint type */
  SELECT
    j.complaint_type,
    t.total_complaints,
    COUNT(j.day)                               AS total_days,
    CORR(j.avg_temp, j.cnt)                    AS pearson_temp_vs_count,
    CORR(j.avg_temp, j.pct_of_day)             AS pearson_temp_vs_percentage
  FROM joined j
  JOIN totals t USING (complaint_type)
  GROUP BY j.complaint_type, t.total_complaints
)
SELECT
  complaint_type,
  total_complaints,
  total_days,
  ROUND(pearson_temp_vs_count,      4) AS pearson_temp_vs_count,
  ROUND(pearson_temp_vs_percentage, 4) AS pearson_temp_vs_percentage
FROM stats
WHERE ABS(pearson_temp_vs_count)      > 0.5
   OR ABS(pearson_temp_vs_percentage) > 0.5
ORDER BY pearson_temp_vs_count DESC;