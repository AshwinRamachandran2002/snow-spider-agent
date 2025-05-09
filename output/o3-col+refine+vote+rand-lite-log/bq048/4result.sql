-- strongest positive and negative correlations between
-- daily average wind speed at JFK (station 744860) and
-- daily 311-complaint proportions, 2011-01-01 – 2020-12-31
WITH wind AS (                       -- daily-avg wind (knots)
  SELECT
    PARSE_DATE(
      '%Y%m%d',
      CONCAT(year, LPAD(mo,2,'0'), LPAD(da,2,'0'))
    )                                   AS d,
    AVG(CAST(wdsp AS FLOAT64))          AS avg_wind
  FROM `bigquery-public-data.noaa_gsod.gsod*`
  WHERE _TABLE_SUFFIX BETWEEN '2011' AND '2020'
    AND stn = '744860'                  -- JFK Airport
    AND SAFE_CAST(wdsp AS FLOAT64) < 999   -- drop missing codes
  GROUP BY d
),
daily_tot AS (                      -- total 311 requests per day
  SELECT DATE(created_date) AS d,
         COUNT(*)           AS n_tot
  FROM   `bigquery-public-data.new_york.311_service_requests`
  WHERE  created_date BETWEEN '2011-01-01' AND '2020-12-31'
  GROUP  BY d
),
type_cnt AS (                       -- daily counts by complaint type
  SELECT DATE(created_date) AS d,
         complaint_type,
         COUNT(*)           AS n_type
  FROM   `bigquery-public-data.new_york.311_service_requests`
  WHERE  created_date BETWEEN '2011-01-01' AND '2020-12-31'
  GROUP  BY d, complaint_type
),
big_types AS (                      -- types with >3 000 requests in period
  SELECT complaint_type
  FROM   `bigquery-public-data.new_york.311_service_requests`
  WHERE  created_date BETWEEN '2011-01-01' AND '2020-12-31'
  GROUP  BY complaint_type
  HAVING COUNT(*) > 3000
),
prop AS (                           -- daily proportion per big type
  SELECT
    t.d,
    t.complaint_type,
    t.n_type / SAFE_CAST(dt.n_tot AS FLOAT64) AS prop
  FROM   type_cnt t
  JOIN   daily_tot dt USING (d)
  WHERE  t.complaint_type IN (SELECT complaint_type FROM big_types)
),
corrs AS (                          -- Pearson correlations
  SELECT
    p.complaint_type,
    CORR(p.prop, w.avg_wind) AS r
  FROM   prop p
  JOIN   wind w USING (d)
  GROUP  BY p.complaint_type
)
-- return most-positive and most-negative correlations
SELECT complaint_type,
       ROUND(r, 4) AS correlation_coeff
FROM (
  (SELECT * FROM corrs ORDER BY r DESC LIMIT 1)   -- strongest positive
  UNION ALL
  (SELECT * FROM corrs ORDER BY r ASC  LIMIT 1)   -- strongest negative
)
ORDER BY correlation_coeff DESC;