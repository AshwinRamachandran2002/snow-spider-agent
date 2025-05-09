-- Correlate daily 311-complaint activity with daily mean temperature (LGA & JFK)
-- over the 10-year window 2008-2017, and list complaint types that
--   • occur > 5 000 times in total, and
--   • show strong |r| > 0.5 correlation with temperature.
-- For each such type return its total complaints, number of
-- temperature-matched days, and Pearson correlations (rounded to 4 dp)
-- vs. both daily counts and daily %-of-total counts.

WITH common_complaints AS (          -- keep only frequent complaint types
  SELECT
    complaint_type,
    COUNT(*) AS total_complaints
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE created_date BETWEEN '2008-01-01' AND '2017-12-31'
  GROUP BY complaint_type
  HAVING total_complaints > 5000
),
daily_311 AS (                       -- daily 311 counts by complaint type
  SELECT
    complaint_type,
    DATE(created_date) AS dt,
    COUNT(*)           AS cnt
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE created_date BETWEEN '2008-01-01' AND '2017-12-31'
  GROUP BY complaint_type, dt
),
daily_temp AS (                      -- daily mean temperature (°F) from LGA & JFK
  SELECT
    DATE(CONCAT(year,'-',mo,'-',da)) AS dt,
    AVG(temp)                       AS avg_temp_f
  FROM `bigquery-public-data.noaa_gsod.gsod20*`
  WHERE _TABLE_SUFFIX BETWEEN '08' AND '17'     -- years 2008-2017
    AND stn IN ('725030','744860')              -- LaGuardia & JFK
    AND temp < 9999                             -- discard sentinel 9999.9
  GROUP BY dt
)

SELECT
  c.complaint_type,
  c.total_complaints,
  COUNT(*)                                     AS valid_days,
  ROUND(CORR(d.cnt                       , t.avg_temp_f),4) AS corr_temp_vs_count,
  ROUND(CORR(d.cnt / c.total_complaints, t.avg_temp_f),4) AS corr_temp_vs_pct
FROM common_complaints AS c
JOIN daily_311        AS d ON d.complaint_type = c.complaint_type
JOIN daily_temp       AS t ON t.dt             = d.dt
GROUP BY
  c.complaint_type,
  c.total_complaints
HAVING ABS(CORR(d.cnt , t.avg_temp_f)) > 0.5   -- strong correlation threshold
ORDER BY ABS(corr_temp_vs_count) DESC;