/* Correlation between NYC 311 complaint types and temperature (2008‑2017) */
WITH
/* ----------------------------------------------------------------- */
/* 1.  Daily mean temperature from LaGuardia (725030) & JFK (744860) */
temp_raw AS (
  SELECT
    PARSE_DATE(
      '%Y-%m-%d',
      CONCAT('20', _TABLE_SUFFIX, '-', LPAD(mo, 2, '0'), '-', LPAD(da, 2, '0'))
    ) AS dt,
    CAST(temp AS FLOAT64) AS temp
  FROM `bigquery-public-data.noaa_gsod.gsod20*`
  WHERE _TABLE_SUFFIX BETWEEN '08' AND '17'     -- years 2008‑2017
    AND stn IN ('725030', '744860')             -- LGA & JFK
    AND temp <> 9999.9                          -- exclude invalid
),
temp AS (
  SELECT
    dt,
    AVG(temp) AS avg_temp                       -- average of the two stations
  FROM temp_raw
  GROUP BY dt
),

/* ----------------------------------------------------------------- */
/* 2. 311 complaints: totals and per‑day counts                      */
complaints_total AS (
  SELECT
    complaint_type,
    COUNT(*) AS total_complaints
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE DATE(created_date) BETWEEN '2008-01-01' AND '2017-12-31'
  GROUP BY complaint_type
),
complaints_daily AS (
  SELECT
    DATE(created_date) AS dt,
    complaint_type,
    COUNT(*) AS daily_cnt
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE DATE(created_date) BETWEEN '2008-01-01' AND '2017-12-31'
  GROUP BY dt, complaint_type
),

/* ----------------------------------------------------------------- */
/* 3. Full panel: every temp day × complaint type                    */
panel AS (
  SELECT
    t.dt,
    ct.complaint_type,
    ct.total_complaints,
    IFNULL(cd.daily_cnt, 0) AS daily_cnt,
    t.avg_temp              AS temp
  FROM temp t
  JOIN complaints_total ct                 -- cross‑join each type to every day
  ON TRUE
  LEFT JOIN complaints_daily cd
    ON cd.dt = t.dt
   AND cd.complaint_type = ct.complaint_type
)

/* ----------------------------------------------------------------- */
/* 4. Correlation calculation & filtering                            */
SELECT
  complaint_type,
  total_complaints,
  COUNT(*)                                        AS total_days_with_temp,
  ROUND(CORR(temp, daily_cnt), 4)                 AS corr_daily_count,
  ROUND(
    CORR(
      temp,
      SAFE_DIVIDE(daily_cnt, total_complaints)
    ),
    4
  )                                               AS corr_daily_pct
FROM panel
GROUP BY complaint_type, total_complaints
HAVING
      total_complaints > 5000
  AND ABS(CORR(temp, daily_cnt)) > 0.5
ORDER BY ABS(corr_daily_count) DESC;