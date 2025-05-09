WITH temp_daily AS (
  -- Daily mean temperature using LaGuardia (725030) and JFK (744860);
  -- invalid readings (9999.9) are removed and the remaining
  -- values are averaged when both stations report.
  SELECT
    date,
    AVG(temp) AS temp_f
  FROM (
    SELECT
      PARSE_DATE('%Y%m%d', CONCAT(year, LPAD(mo,2,'0'), LPAD(da,2,'0'))) AS date,
      CAST(temp AS FLOAT64) AS temp
    FROM `bigquery-public-data.noaa_gsod.gsod20*`
    WHERE stn IN ('725030', '744860')
      AND CAST(year AS INT64) BETWEEN 2008 AND 2017
      AND temp <> 9999.9
  )
  GROUP BY date
),
-- Daily complaint counts by type
complaints_raw AS (
  SELECT
    DATE(created_date)                           AS date,
    complaint_type,
    COUNT(*)                                     AS cnt
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE created_date >= '2008-01-01'
    AND created_date <  '2018-01-01'
  GROUP BY date, complaint_type
),
-- Total complaints per day (to build percentages)
daily_totals AS (
  SELECT
    date,
    SUM(cnt) AS total_cnt
  FROM complaints_raw
  GROUP BY date
),
-- Add daily share of each complaint type
complaints_with_pct AS (
  SELECT
    cr.date,
    cr.complaint_type,
    cr.cnt,
    SAFE_DIVIDE(cr.cnt, dt.total_cnt) AS pct
  FROM complaints_raw cr
  JOIN daily_totals  dt USING (date)
),
-- Keep only complaint types with at least 5 000 occurrences
complaint_types_over_5k AS (
  SELECT
    complaint_type,
    SUM(cnt) AS total_complaints
  FROM complaints_raw
  GROUP BY complaint_type
  HAVING total_complaints > 5000
),
-- Build the full day × complaint_type grid so that
-- missing‑day counts become zeros
complaints_full AS (
  SELECT
    t.date,
    ct.complaint_type,
    t.temp_f,
    COALESCE(cwp.cnt, 0) AS cnt,
    COALESCE(cwp.pct, 0) AS pct
  FROM temp_daily                    t
  CROSS JOIN complaint_types_over_5k ct
  LEFT JOIN complaints_with_pct      cwp
         ON  cwp.date           = t.date
         AND cwp.complaint_type = ct.complaint_type
)
-- Final correlations and filtering for |ρ| > 0.5
SELECT
  complaint_type,
  SUM(cnt)            AS total_complaints,
  COUNT(*)            AS total_valid_days,
  ROUND(CORR(temp_f, cnt), 4) AS corr_cnt,
  ROUND(CORR(temp_f, pct), 4) AS corr_pct
FROM complaints_full
GROUP BY complaint_type
HAVING GREATEST(ABS(CORR(temp_f, cnt)), ABS(CORR(temp_f, pct))) > 0.5
ORDER BY complaint_type;