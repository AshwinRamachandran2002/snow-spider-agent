WITH temp AS (   -- daily mean temperature (LGA & JFK, 2008-2017)
  SELECT
    DATE(CONCAT(year,'-',LPAD(mo,2,'0'),'-',LPAD(da,2,'0'))) AS day,
    AVG(temp)                                                AS f_temp
  FROM `bigquery-public-data.noaa_gsod.gsod20*`
  --  _TABLE_SUFFIX is the 2-digit year after the fixed prefix “gsod20”
  WHERE _TABLE_SUFFIX IN ('08','09','10','11','12','13','14','15','16','17')
    AND stn IN ('725030','744860')      -- LaGuardia & JFK
    AND temp <> 9999.9                  -- discard invalid readings
  GROUP BY day
),
complaints AS (   -- daily 311 complaint counts
  SELECT
    DATE(created_date) AS day,
    complaint_type,
    COUNT(*)           AS daily_cnt
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE EXTRACT(YEAR FROM created_date) BETWEEN 2008 AND 2017
  GROUP BY day, complaint_type
),
tot AS (          -- complaint types with >5 000 total complaints
  SELECT
    complaint_type,
    SUM(daily_cnt) AS tot_cnt
  FROM complaints
  GROUP BY complaint_type
  HAVING tot_cnt > 5000
),
joined AS (       -- merge temperature with complaint counts
  SELECT
    c.complaint_type,
    t.f_temp,
    c.daily_cnt,
    c.daily_cnt / tot.tot_cnt AS daily_pct
  FROM complaints c
  JOIN tot  ON c.complaint_type = tot.complaint_type
  JOIN temp t ON c.day = t.day
)
SELECT
  complaint_type,
  tot_cnt                             AS total_complaints,
  COUNT(*)                            AS days_with_temp,
  ROUND(CORR(f_temp, daily_cnt),4)    AS corr_cnt,
  ROUND(CORR(f_temp, daily_pct),4)    AS corr_pct
FROM joined
JOIN tot USING (complaint_type)
GROUP BY complaint_type, tot_cnt
HAVING ABS(CORR(f_temp, daily_cnt)) > 0.5      -- strong correlation
ORDER BY ABS(corr_cnt) DESC;