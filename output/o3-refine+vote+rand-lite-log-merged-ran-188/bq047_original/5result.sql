-- Temperature‑complaint correlation for NYC (2008‑2017)
WITH temp_raw AS (   -- daily records for LaGuardia (725030) & JFK (744860)
  SELECT
    PARSE_DATE('%Y%m%d', CONCAT(year, LPAD(mo,2,'0'), LPAD(da,2,'0'))) AS dt,
    CAST(temp AS FLOAT64)                                    AS temp_f
  FROM `bigquery-public-data.noaa_gsod.gsod*`
  WHERE _TABLE_SUFFIX BETWEEN '2008' AND '2017'
    AND stn IN ('725030','744860')
    AND temp <> 9999.9                                        -- discard invalid
),
temp_daily AS (        -- average of the two airports per day
  SELECT
    dt,
    AVG(temp_f) AS avg_temp_f
  FROM temp_raw
  GROUP BY dt
),
compl_daily AS (       -- 311 complaints per day & type
  SELECT
    DATE(created_date)          AS dt,
    complaint_type,
    COUNT(*)                    AS daily_cnt
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE created_date BETWEEN '2008-01-01' AND '2017-12-31'
  GROUP BY dt, complaint_type
),
compl_tot AS (         -- total per complaint type
  SELECT
    complaint_type,
    SUM(daily_cnt) AS total_cnt
  FROM compl_daily
  GROUP BY complaint_type
  HAVING total_cnt > 5000          -- keep only popular types
),
base AS (               -- expand to every temp day (fill 0 where no complaints)
  SELECT
    t.dt,
    t.avg_temp_f,
    c.complaint_type,
    c.total_cnt,
    IFNULL(d.daily_cnt,0) AS daily_cnt
  FROM temp_daily      t
  CROSS JOIN compl_tot c
  LEFT  JOIN compl_daily d
         ON d.dt = t.dt AND d.complaint_type = c.complaint_type
)
SELECT
  complaint_type,
  total_cnt                        AS total_complaints,
  COUNT(*)                         AS total_valid_temp_days,
  ROUND(CORR(avg_temp_f, CAST(daily_cnt AS FLOAT64)),4)          AS corr_daily_count,
  ROUND(CORR(avg_temp_f,
             CAST(daily_cnt AS FLOAT64)/total_cnt),4)            AS corr_daily_percentage
FROM base
GROUP BY complaint_type, total_cnt
HAVING ABS(CORR(avg_temp_f, CAST(daily_cnt AS FLOAT64))) > 0.5
    OR ABS(CORR(avg_temp_f, CAST(daily_cnt AS FLOAT64)/total_cnt)) > 0.5
ORDER BY complaint_type;