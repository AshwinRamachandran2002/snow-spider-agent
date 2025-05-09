#standardSQL
WITH temp_base AS (   -- 1.  Daily temperatures (LaGuardia & JFK) 2008‑2017
  SELECT
    PARSE_DATE('%Y%m%d', CONCAT(year, LPAD(mo,2,'0'), LPAD(da,2,'0'))) AS dt,
    CAST(temp AS FLOAT64) AS temp ,
    stn
  FROM `bigquery-public-data.noaa_gsod.gsod20*`
  WHERE year BETWEEN '2008' AND '2017'          -- keep 2008‑2017
    AND stn IN ('725030','744860')              -- LaGuardia & JFK
    AND temp <> 9999.9                          -- remove invalid values
),
daily_temp AS (                                 -- average of the two airports
  SELECT dt, AVG(temp) AS avg_temp
  FROM temp_base
  GROUP BY dt
),

-- 2.  311 complaints 2008‑2017
complaints_raw AS (
  SELECT DATE(created_date) AS dt,
         complaint_type
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE created_date >= '2008-01-01'
    AND created_date <  '2018-01-01'
),

-- daily complaint counts
complaints AS (
  SELECT dt, complaint_type, COUNT(*) AS daily_cnt
  FROM complaints_raw
  GROUP BY dt, complaint_type
),

-- complaint types with > 5 000 occurrences
totals AS (
  SELECT complaint_type, COUNT(*) AS tot_cnt
  FROM complaints_raw
  GROUP BY complaint_type
  HAVING tot_cnt > 5000
),

-- calendar of all days that have valid temperature
calendar AS (SELECT dt FROM daily_temp),

-- 3.  add zero‑count rows for days with no complaints
all_days AS (
  SELECT t.complaint_type, c.dt
  FROM totals t
  CROSS JOIN calendar c
),

daily_full AS (
  SELECT
    a.complaint_type,
    a.dt,
    COALESCE(d.daily_cnt, 0) AS daily_cnt
  FROM all_days a
  LEFT JOIN complaints d
    ON d.complaint_type = a.complaint_type
   AND d.dt             = a.dt
),

-- 4.  join with temperature & compute daily percentage of total
joined AS (
  SELECT
    f.complaint_type,
    f.dt,
    temp.avg_temp                    AS temp,
    f.daily_cnt,
    CAST(f.daily_cnt AS FLOAT64) / t.tot_cnt AS daily_pct
  FROM daily_full f
  JOIN daily_temp temp ON temp.dt = f.dt
  JOIN totals     t    ON t.complaint_type = f.complaint_type
),

-- 5.  correlation statistics
stats AS (
  SELECT
    j.complaint_type,
    t.tot_cnt                       AS total_complaints,
    COUNT(*)                        AS total_days,
    CORR(j.temp, j.daily_cnt)       AS corr_cnt,
    CORR(j.temp, j.daily_pct)       AS corr_pct
  FROM joined j
  JOIN totals t USING (complaint_type)
  GROUP BY complaint_type, total_complaints
)

-- 6.  final output: strong absolute correlation (>0.5)
SELECT
  complaint_type,
  total_complaints,
  total_days,
  ROUND(corr_cnt, 4) AS corr_daily_count,
  ROUND(corr_pct, 4) AS corr_daily_pct
FROM stats
WHERE ABS(corr_cnt) > 0.5
ORDER BY complaint_type;