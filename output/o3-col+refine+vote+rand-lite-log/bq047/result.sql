-- Complaint-temperature correlations in NYC (2008-2017)
WITH temps AS (     -- daily mean temperature (°F) across LGA & JFK
  SELECT
    DATE(CONCAT(year,'-',LPAD(mo,2,'0'),'-',LPAD(da,2,'0'))) AS obs_date,
    AVG(temp)                                               AS avg_temp
  FROM `bigquery-public-data.noaa_gsod.gsod*`
  WHERE stn IN ('725030','744860')                     -- LaGuardia & JFK
    AND SAFE_CAST(_TABLE_SUFFIX AS INT64) BETWEEN 2008 AND 2017
    AND temp < 9999.9                                  -- discard invalid
  GROUP BY obs_date
),
daily_type AS (       -- daily counts by complaint type
  SELECT
    DATE(created_date)        AS obs_date,
    complaint_type,
    COUNT(*)                  AS type_cnt
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE DATE(created_date) BETWEEN '2008-01-01' AND '2017-12-31'
  GROUP BY obs_date, complaint_type
),
daily_tot AS (        -- total 311 calls per day
  SELECT
    DATE(created_date) AS obs_date,
    COUNT(*)           AS all_cnt
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE DATE(created_date) BETWEEN '2008-01-01' AND '2017-12-31'
  GROUP BY obs_date
),
joined AS (           -- combine temperature, type counts, and totals
  SELECT
    dt.complaint_type,
    t.obs_date,
    t.avg_temp,
    dt.type_cnt,
    dtot.all_cnt,
    SAFE_DIVIDE(dt.type_cnt, dtot.all_cnt) AS pct_of_day
  FROM temps       t
  JOIN daily_tot   dtot ON dtot.obs_date = t.obs_date
  JOIN daily_type  dt   ON dt.obs_date   = t.obs_date
)
SELECT
  complaint_type,
  SUM(type_cnt)                         AS total_complaints,
  COUNT(DISTINCT obs_date)              AS days_with_temp,
  ROUND(CORR(avg_temp, type_cnt), 4)    AS corr_temp_count,
  ROUND(CORR(avg_temp, pct_of_day), 4)  AS corr_temp_pct
FROM joined
GROUP BY complaint_type
HAVING total_complaints > 5000
   AND ABS(corr_temp_count) > 0.5
ORDER BY ABS(corr_temp_count) DESC;