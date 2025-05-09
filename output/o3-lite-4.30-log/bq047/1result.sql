WITH union_temp AS (
  -- Daily mean temperature (°F) averaged across LaGuardia (725030) and JFK (744860)
  SELECT
    DATE(CONCAT(year,'-',LPAD(mo,2,'0'),'-',LPAD(da,2,'0'))) AS day,
    AVG(temp) AS avg_temp
  FROM (
        SELECT * FROM `bigquery-public-data.noaa_gsod.gsod2008` UNION ALL
        SELECT * FROM `bigquery-public-data.noaa_gsod.gsod2009` UNION ALL
        SELECT * FROM `bigquery-public-data.noaa_gsod.gsod2010` UNION ALL
        SELECT * FROM `bigquery-public-data.noaa_gsod.gsod2011` UNION ALL
        SELECT * FROM `bigquery-public-data.noaa_gsod.gsod2012` UNION ALL
        SELECT * FROM `bigquery-public-data.noaa_gsod.gsod2013` UNION ALL
        SELECT * FROM `bigquery-public-data.noaa_gsod.gsod2014` UNION ALL
        SELECT * FROM `bigquery-public-data.noaa_gsod.gsod2015` UNION ALL
        SELECT * FROM `bigquery-public-data.noaa_gsod.gsod2016` UNION ALL
        SELECT * FROM `bigquery-public-data.noaa_gsod.gsod2017`
  )
  WHERE stn IN ('725030','744860')      -- LaGuardia & JFK
    AND temp <> 9999.9                  -- exclude missing temps
  GROUP BY day
),
daily_311 AS (
  -- Daily complaint counts by type for 2008‑2017
  SELECT
    DATE(created_date) AS day,
    complaint_type,
    COUNT(*)           AS cnt
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE created_date BETWEEN '2008-01-01' AND '2017-12-31'
  GROUP BY day, complaint_type
),
daily_tot AS (
  -- Daily total number of complaints (for percentage share)
  SELECT
    day,
    SUM(cnt) AS tot_cnt
  FROM daily_311
  GROUP BY day
),
daily_combined AS (
  -- Merge complaints with temperature and compute daily percentage share
  SELECT
    d.day,
    d.complaint_type,
    d.cnt,
    d.cnt / CAST(t.tot_cnt AS FLOAT64) AS pct_of_day,
    u.avg_temp
  FROM daily_311 d
  JOIN union_temp u USING (day)  -- only days with valid temperature
  JOIN daily_tot  t USING (day)
),
stats AS (
  -- Aggregate totals and correlations by complaint type
  SELECT
    complaint_type,
    SUM(cnt)            AS total_complaints,
    COUNT(DISTINCT day) AS total_days,
    CORR(cnt,       avg_temp) AS corr_cnt,
    CORR(pct_of_day, avg_temp) AS corr_pct
  FROM daily_combined
  GROUP BY complaint_type
)
SELECT
  complaint_type,
  total_complaints,
  total_days,
  ROUND(corr_cnt,  4) AS pearson_temp_vs_count,
  ROUND(corr_pct,  4) AS pearson_temp_vs_percentage
FROM stats
WHERE total_complaints > 5000
  AND ABS(corr_cnt) > 0.5
ORDER BY ABS(corr_cnt) DESC, complaint_type;