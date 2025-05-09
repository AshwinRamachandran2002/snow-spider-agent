-- Complaint-type proportions vs. JFK daily mean wind speed (2011-2020)
-- strongest positive and negative Pearson correlations (types ≥3 000 total requests)
WITH wind AS (
  SELECT
    PARSE_DATE('%Y%m%d', CONCAT(year, LPAD(mo,2,'0'), LPAD(da,2,'0'))) AS dt,
    SAFE_CAST(wdsp AS FLOAT64)                                         AS wind_knots
  FROM `bigquery-public-data.noaa_gsod.gsod*`
  WHERE _TABLE_SUFFIX BETWEEN '2011' AND '2020'
    AND stn = '744860'                    -- JFK Airport station
    AND SAFE_CAST(wdsp AS FLOAT64) < 900  -- drop filler 999.9
),
daily_tot AS (
  SELECT
    DATE(created_date) AS dt,
    COUNT(*)           AS n_total
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE created_date BETWEEN '2011-01-01' AND '2020-12-31'
  GROUP BY dt
),
daily_type AS (
  SELECT
    DATE(created_date) AS dt,
    complaint_type,
    COUNT(*)           AS n_type
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE created_date BETWEEN '2011-01-01' AND '2020-12-31'
  GROUP BY dt, complaint_type
),
props AS (   -- daily proportion of each complaint type
  SELECT
    t.dt,
    t.complaint_type,
    n_type / n_total AS prop_type
  FROM daily_type t
  JOIN daily_tot USING (dt)
),
big_types AS (   -- keep types with ≥3 000 total requests
  SELECT complaint_type
  FROM `bigquery-public-data.new_york.311_service_requests`
  WHERE created_date BETWEEN '2011-01-01' AND '2020-12-31'
  GROUP BY complaint_type
  HAVING COUNT(*) >= 3000
),
corrs AS (       -- Pearson correlations
  SELECT
    complaint_type,
    CORR(prop_type, wind_knots) AS r
  FROM props
  JOIN wind USING (dt)
  JOIN big_types USING (complaint_type)
  GROUP BY complaint_type
)
SELECT
  complaint_type,
  ROUND(r, 4) AS correlation
FROM (
  SELECT
    complaint_type,
    r,
    RANK() OVER (ORDER BY r DESC) AS pos_rank,
    RANK() OVER (ORDER BY r ASC)  AS neg_rank
  FROM corrs
)
WHERE pos_rank = 1           -- strongest positive
   OR neg_rank = 1           -- strongest negative
ORDER BY correlation DESC;   -- positive first, then negative