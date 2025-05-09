WITH temperature AS (
  -- daily mean temperature (°F) averaged across LaGuardia (725030) and JFK (744860)
  SELECT
    DATE(CAST(year AS INT64), CAST(mo AS INT64), CAST(da AS INT64)) AS day,
    AVG(CAST(temp AS FLOAT64))                         AS avg_temp
  FROM `bigquery-public-data.noaa_gsod.gsod20*`
  WHERE _TABLE_SUFFIX IN ('08','09','10','11','12','13','14','15','16','17')  -- 2008‑2017
    AND stn IN ('725030','744860')                       -- LGA and JFK
    AND temp < 9000                                      -- discard 9999.9 (missing)
  GROUP BY day
),
-- 311 daily counts by complaint type
daily_counts AS (
  SELECT
    DATE(created_date)                     AS day,
    complaint_type,
    COUNT(*)                               AS cnt
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE created_date BETWEEN '2008-01-01' AND '2017-12-31'
  GROUP BY day, complaint_type
),
-- total 311 complaints each day (all types)
daily_totals AS (
  SELECT
    DATE(created_date)                     AS day,
    COUNT(*)                               AS total_cnt
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE created_date BETWEEN '2008-01-01' AND '2017-12-31'
  GROUP BY day
),
-- complaint types occurring > 5 000 times in the 10‑year window
types_over_5k AS (
  SELECT
    complaint_type,
    SUM(cnt) AS total_complaints
  FROM daily_counts
  GROUP BY complaint_type
  HAVING total_complaints > 5000
),
-- assemble one row per (day , complaint_type) with zero‑fill,
-- keep only days that have a valid temperature reading
analysis_data AS (
  SELECT
    t.day,
    ct.complaint_type,
    IFNULL(dc.cnt,0)                                          AS daily_cnt,
    t.avg_temp,
    SAFE_DIVIDE(IFNULL(dc.cnt,0), dt.total_cnt)               AS daily_pct
  FROM temperature t
  CROSS JOIN types_over_5k  ct
  LEFT  JOIN daily_counts dc ON dc.day = t.day
                             AND dc.complaint_type = ct.complaint_type
  JOIN  daily_totals  dt ON dt.day = t.day                    -- ensures denominator exists
)
-- final correlations
SELECT
  ad.complaint_type,
  t.total_complaints,
  COUNT(*)                                   AS total_days_with_temp,
  ROUND(CORR(ad.avg_temp, ad.daily_cnt), 4)  AS corr_daily_count,
  ROUND(CORR(ad.avg_temp, ad.daily_pct), 4)  AS corr_daily_pct
FROM analysis_data ad
JOIN types_over_5k t
  ON ad.complaint_type = t.complaint_type
GROUP BY ad.complaint_type, t.total_complaints
HAVING ABS(corr_daily_count) > 0.5
    OR ABS(corr_daily_pct)  > 0.5
ORDER BY ad.complaint_type;