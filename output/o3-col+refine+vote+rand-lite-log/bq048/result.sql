WITH -- 1. 311 requests 2011-2020
requests AS (
  SELECT
    DATE(created_date)               AS day,
    complaint_type
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE EXTRACT(YEAR FROM created_date) BETWEEN 2011 AND 2020
),

-- 2. Daily totals (all complaints)  
daily_tot AS (
  SELECT day, COUNT(*) AS total_reqs
  FROM requests
  GROUP BY day
),

-- 3. Daily counts per complaint type  
daily_type AS (
  SELECT day, complaint_type, COUNT(*) AS type_cnt
  FROM requests
  GROUP BY day, complaint_type
),

-- 4. Daily proportions of each complaint type  
daily_prop AS (
  SELECT
    dt.day,
    dt.complaint_type,
    dt.type_cnt,
    dt.type_cnt / CAST(t.total_reqs AS FLOAT64) AS proportion
  FROM daily_type dt
  JOIN daily_tot t USING (day)
),

-- 5. Daily mean wind speed at JFK station 744860 (2011-2020)  
wind AS (
  SELECT
    DATE(CONCAT(year, '-', LPAD(mo,2,'0'), '-', LPAD(da,2,'0'))) AS day,
    SAFE_CAST(wdsp AS FLOAT64) AS wind_kt
  FROM `bigquery-public-data.noaa_gsod.gsod*`
  WHERE _TABLE_SUFFIX BETWEEN '2011' AND '2020'
    AND stn = '744860'
),

-- 6. Correlation of daily proportion vs. wind for each complaint type  
corr_table AS (
  SELECT
    dp.complaint_type,
    SUM(dp.type_cnt)                           AS total_requests,
    CORR(dp.proportion, w.wind_kt)             AS corr_coeff
  FROM daily_prop dp
  JOIN wind w USING (day)
  GROUP BY dp.complaint_type
  HAVING total_requests > 3000          -- only keep sufficiently frequent types
     AND corr_coeff IS NOT NULL
),

-- 7. Pick strongest positive & strongest negative correlations  
extremes AS (
  (SELECT complaint_type,
          ROUND(corr_coeff, 4) AS correlation
   FROM corr_table
   ORDER BY corr_coeff DESC
   LIMIT 1)
  UNION ALL
  (SELECT complaint_type,
          ROUND(corr_coeff, 4) AS correlation
   FROM corr_table
   ORDER BY corr_coeff ASC
   LIMIT 1)
)

SELECT * FROM extremes;