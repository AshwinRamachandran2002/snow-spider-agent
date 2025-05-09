/* 311 complaints vs. temperature (LaGuardia + JFK), 2008-2017
   – keep complaint types with >5 000 cases and |r| > 0.5              */

WITH complaints AS (                          -- all 311 rows, 2008-2017
  SELECT
    DATE(created_date) AS day,
    complaint_type
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE EXTRACT(YEAR FROM created_date) BETWEEN 2008 AND 2017
),

type_totals AS (                              -- only types ≥5 000 cases
  SELECT
    complaint_type,
    COUNT(*) AS total_complaints
  FROM complaints
  GROUP BY complaint_type
  HAVING COUNT(*) > 5000
),

daily_type AS (                               -- daily count per type
  SELECT
    day,
    complaint_type,
    COUNT(*) AS type_cnt
  FROM complaints
  GROUP BY day, complaint_type
),

daily_all AS (                                -- total 311 count per day
  SELECT
    day,
    COUNT(*) AS all_cnt
  FROM complaints
  GROUP BY day
),

temps_raw AS (                                -- GSOD rows for two airports
  SELECT
    PARSE_DATE('%Y%m%d', CONCAT(year, mo, da)) AS day,
    CAST(temp AS FLOAT64)                      AS temp
  FROM `bigquery-public-data.noaa_gsod.gsod20*`
  WHERE _TABLE_SUFFIX BETWEEN '08' AND '17'    -- 2008-2017 (suffix = 08-17)
    AND stn IN ('725030', '744860')            -- LGA & JFK
    AND temp < 9999.9                          -- drop sentinel values
),

temps AS (                                    -- mean temperature per day
  SELECT
    day,
    AVG(temp) AS temp
  FROM temps_raw
  GROUP BY day
),

joined AS (                                   -- merge counts & temperature
  SELECT
    dt.complaint_type,
    dt.day,
    dt.type_cnt,
    da.all_cnt,
    tp.temp
  FROM daily_type  AS dt
  JOIN daily_all   AS da USING (day)
  JOIN temps       AS tp USING (day)
  JOIN type_totals AS tt USING (complaint_type)   -- enforce 5 000-case filter
)

SELECT
  complaint_type,
  tt.total_complaints,
  COUNT(DISTINCT day)                               AS valid_days,
  ROUND(CORR(type_cnt         , temp), 4) AS r_count,
  ROUND(CORR(type_cnt / all_cnt, temp), 4) AS r_pct
FROM joined
JOIN type_totals AS tt USING (complaint_type)
GROUP BY complaint_type, tt.total_complaints
HAVING ABS(CORR(type_cnt, temp)) > 0.5
ORDER BY ABS(r_count) DESC;