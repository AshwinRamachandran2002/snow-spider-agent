-- Relationship between 311 complaint-types and daily temperature (LGA + JFK)
WITH daily_temp AS (                 -- mean daily °F for LGA (725030) + JFK (744860)
  SELECT
    DATE(CAST(year AS INT64),CAST(mo AS INT64),CAST(da AS INT64))  AS day,
    AVG(temp)                                                     AS mean_temp_f
  FROM `bigquery-public-data.noaa_gsod.gsod*`
  WHERE _TABLE_SUFFIX BETWEEN '2008' AND '2017'
    AND stn IN ('725030','744860')          -- LaGuardia & JFK
    AND temp <> 9999.9                      -- discard sentinel
  GROUP BY day
),
daily_complaints AS (                -- per-day counts by complaint-type
  SELECT
    DATE(created_date)        AS day,
    LOWER(complaint_type)     AS complaint_type,
    COUNT(*)                  AS cnt
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE DATE(created_date) BETWEEN '2008-01-01' AND '2017-12-31'
  GROUP BY day, complaint_type
),
totals AS (                          -- keep types with >5 000 total complaints
  SELECT complaint_type, SUM(cnt) AS tot_cnt
  FROM daily_complaints
  GROUP BY complaint_type
  HAVING tot_cnt > 5000
),
joined AS (                          -- temperature joined to complaint counts
  SELECT
    d.complaint_type,
    t.day,
    t.mean_temp_f,
    d.cnt,
    SAFE_DIVIDE(d.cnt, tot_cnt) AS pct_of_all
  FROM daily_complaints d
  JOIN totals USING (complaint_type)
  JOIN daily_temp t USING (day)
)
SELECT
  complaint_type,
  SUM(cnt)                           AS total_complaints,
  COUNT(DISTINCT day)                AS temp_days,
  ROUND(CORR(mean_temp_f, cnt),4)    AS corr_cnt,
  ROUND(CORR(mean_temp_f, pct_of_all),4) AS corr_pct
FROM joined
GROUP BY complaint_type
HAVING ABS(corr_cnt) > 0.5
ORDER BY ABS(corr_cnt) DESC;