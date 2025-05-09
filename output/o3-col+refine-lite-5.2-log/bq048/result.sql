-- Strongest positive and negative correlations between daily wind speed at JFK (station 744860)
-- and the daily proportion of 311 complaint types that logged > 3 000 requests (2011‑2020)

WITH
-- 1.  Daily mean wind speed (knots) at JFK Airport
wind AS (
  SELECT
    PARSE_DATE('%Y%m%d', CONCAT(year, LPAD(mo,2,'0'), LPAD(da,2,'0'))) AS wx_date,
    CAST(wdsp AS FLOAT64)                                   AS mean_wind_kt
  FROM `bigquery-public-data.noaa_gsod.gsod20*`
  WHERE _TABLE_SUFFIX BETWEEN '11' AND '20'        -- 2011‑2020
    AND stn = '744860'                             -- JFK Airport
    AND CAST(wdsp AS FLOAT64) < 999.9              -- exclude missing
),

-- 2.  Total 311 requests per day
daily_totals AS (
  SELECT
    DATE(created_date)          AS req_date,
    COUNT(*)                    AS all_cnt
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE created_date BETWEEN '2011-01-01' AND '2020-12-31'
  GROUP BY req_date
),

-- 3.  Daily counts for each complaint type
daily_types AS (
  SELECT
    DATE(created_date)          AS req_date,
    complaint_type,
    COUNT(*)                    AS type_cnt
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE created_date BETWEEN '2011-01-01' AND '2020-12-31'
  GROUP BY req_date, complaint_type
),

-- 4.  Complaint types with > 3 000 total requests in the study window
type_totals AS (
  SELECT
    complaint_type,
    COUNT(*) AS total_reqs
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE created_date BETWEEN '2011-01-01' AND '2020-12-31'
  GROUP BY complaint_type
  HAVING total_reqs > 3000
),

-- 5.  Join to get daily proportion of each qualifying type and matching wind speed
joined AS (
  SELECT
    dt.complaint_type,
    SAFE_DIVIDE(dt.type_cnt, d.all_cnt) AS proportion,
    w.mean_wind_kt
  FROM daily_types dt
  JOIN daily_totals d  ON d.req_date = dt.req_date
  JOIN wind         w  ON w.wx_date   = dt.req_date
  JOIN type_totals  tt ON tt.complaint_type = dt.complaint_type
),

-- 6.  Pearson correlations for every qualifying complaint type
correlations AS (
  SELECT
    complaint_type,
    CORR(proportion, mean_wind_kt) AS corr_coeff
  FROM joined
  GROUP BY complaint_type
),

-- 7.  Identify the strongest positive and strongest negative correlations
extremes AS (
  SELECT *
  FROM (
    SELECT
      complaint_type,
      corr_coeff,
      ROW_NUMBER() OVER (ORDER BY corr_coeff DESC) AS pos_rank,
      ROW_NUMBER() OVER (ORDER BY corr_coeff ASC)  AS neg_rank
    FROM correlations
  )
  WHERE pos_rank = 1 OR neg_rank = 1
)

-- 8.  Final result
SELECT
  complaint_type,
  ROUND(corr_coeff, 4) AS correlation_coefficient
FROM extremes
ORDER BY correlation_coefficient DESC;