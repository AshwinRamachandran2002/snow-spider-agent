WITH temp_daily AS (
  -- Daily average temperature (°F) across LaGuardia (725030) and JFK (744860)
  SELECT
    DATE(CONCAT(year, '-', LPAD(mo,2,'0'), '-', LPAD(da,2,'0'))) AS date,
    AVG(CAST(temp AS FLOAT64))                           AS avg_temp
  FROM `bigquery-public-data.noaa_gsod.gsod20*`
  WHERE _TABLE_SUFFIX BETWEEN '08' AND '17'              -- 2008‑2017
    AND stn IN ('725030','744860')                       -- LGA & JFK
    AND temp != 9999.9                                   -- valid temps only
  GROUP BY date
),
daily_complaints AS (
  -- Complaint counts per day & type
  SELECT
    DATE(created_date)             AS date,
    complaint_type,
    COUNT(*)                       AS complaints
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE created_date BETWEEN '2008-01-01' AND '2017-12-31'
  GROUP BY date, complaint_type
),
daily_totals AS (
  -- Total complaints each day (for percentage calculation)
  SELECT
    date,
    SUM(complaints) AS total_complaints
  FROM daily_complaints
  GROUP BY date
),
joined AS (
  -- Combine complaints with daily temperature; keep only days having temperature
  SELECT
    dc.complaint_type,
    dc.date,
    dc.complaints,
    SAFE_DIVIDE(CAST(dc.complaints AS FLOAT64),
                CAST(dt.total_complaints AS FLOAT64))    AS pct_of_day,
    td.avg_temp
  FROM daily_complaints dc
  JOIN daily_totals dt   USING (date)
  JOIN temp_daily  td    USING (date)
),
stats AS (
  -- Correlations and overall totals per complaint type
  SELECT
    complaint_type,
    SUM(complaints)                                    AS total_complaints,
    COUNT(*)                                           AS days_with_temp,
    CORR(avg_temp, CAST(complaints AS FLOAT64))        AS corr_count,
    CORR(avg_temp, pct_of_day)                         AS corr_pct
  FROM joined
  GROUP BY complaint_type
  HAVING total_complaints > 5000
     AND (ABS(corr_count) > 0.5 OR ABS(corr_pct) > 0.5)
)
SELECT
  complaint_type,
  total_complaints,
  days_with_temp,
  ROUND(corr_count,4)  AS corr_count,
  ROUND(corr_pct,4)    AS corr_pct
FROM stats
ORDER BY ABS(corr_count) DESC, complaint_type;