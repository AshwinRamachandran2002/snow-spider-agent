-- relationship between NYC 311 complaint activity and daily temperature
WITH temp_raw AS (
  -- grab daily mean temperatures for LaGuardia (725030) and JFK (744860)
  SELECT
    DATE(CAST(year AS INT64),           -- build a DATE column
         CAST(mo   AS INT64),
         CAST(da   AS INT64))         AS day,
    CAST(temp AS FLOAT64)              AS temp_f
  FROM `bigquery-public-data.noaa_gsod.gsod20*`
  WHERE _TABLE_SUFFIX BETWEEN '08' AND '17'          -- 2008‑2017 inclusive
    AND stn IN ('725030','744860')                   -- LGA & JFK
    AND CAST(temp AS FLOAT64) != 9999.9              -- discard invalid temps
),
daily_temp AS (
  -- average the two airports (use whichever are present)
  SELECT
    day,
    AVG(temp_f) AS avg_temp_f
  FROM temp_raw
  GROUP BY day
),

-- 311 complaints aggregated by day & type
complaints_daily AS (
  SELECT
    DATE(created_date)            AS day,
    complaint_type,
    COUNT(*)                      AS daily_count
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE created_date >= '2008-01-01'
    AND created_date <  '2018-01-01'
  GROUP BY day, complaint_type
),

-- keep only complaint types with sizeable volume
types_totals AS (
  SELECT
    complaint_type,
    SUM(daily_count) AS total_complaints
  FROM complaints_daily
  GROUP BY complaint_type
  HAVING total_complaints > 5000
),

-- calendar of all days for which we have a valid temperature
calendar AS (
  SELECT day, avg_temp_f FROM daily_temp
),

-- cross‑join calendar with each large‑volume complaint type,
-- filling missing days with zero complaints
joined AS (
  SELECT
    cal.day,
    cal.avg_temp_f,
    t.complaint_type,
    IFNULL(cd.daily_count,0)                   AS daily_count,
    t.total_complaints
  FROM calendar               AS cal
  CROSS JOIN types_totals     AS t
  LEFT JOIN complaints_daily  AS cd
         ON  cd.day = cal.day
         AND cd.complaint_type = t.complaint_type
)

-- final correlations & filtering
SELECT
  complaint_type,
  total_complaints,
  (SELECT COUNT(*) FROM calendar)                    AS total_days_with_temperature,
  ROUND(CORR(avg_temp_f, daily_count)                                         ,4) AS corr_daily_count,
  ROUND(CORR(avg_temp_f,
             daily_count / CAST(total_complaints AS FLOAT64))                 ,4) AS corr_daily_pct
FROM joined
GROUP BY complaint_type, total_complaints
HAVING ABS(corr_daily_count) > 0.5
    OR ABS(corr_daily_pct)  > 0.5
ORDER BY complaint_type;