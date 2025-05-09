-- Which Utah county saw the largest percentage rise in construction employment
-- (average of the 3rd-month employment level of each quarter) between 2000 and 2018?
WITH qtr_data AS (   -- pull only the needed quarters in 2000 and 2018
  SELECT
    CAST(SUBSTR(_TABLE_SUFFIX, 1, 4) AS INT64)         AS yr,
    geoid,
    month3_emplvl_23_construction                      AS month3_jobs
  FROM
    `bigquery-public-data.bls_qcew.*`
  WHERE
    _TABLE_SUFFIX IN ('2000_q1','2000_q2','2000_q3','2000_q4',
                      '2018_q1','2018_q2','2018_q3','2018_q4')
    AND LEFT(geoid,2) = '49'          -- Utah FIPS prefix
),
yearly_avg AS (       -- average the 3rd-month employment over the four quarters
  SELECT
    geoid,
    yr,
    AVG(month3_jobs) AS avg_jobs
  FROM qtr_data
  GROUP BY geoid, yr
),
paired AS (           -- table with both years on one row
  SELECT
    a.geoid,
    a.avg_jobs AS avg_2000,
    b.avg_jobs AS avg_2018,
    SAFE_DIVIDE(b.avg_jobs - a.avg_jobs, a.avg_jobs) * 100 AS pct_change
  FROM  yearly_avg a
  JOIN  yearly_avg b
    ON  a.geoid = b.geoid
   AND  a.yr = 2000
   AND  b.yr = 2018
)
SELECT
  c.county_name,
  ROUND(p.pct_change, 2) AS pct_increase
FROM paired p
JOIN `bigquery-public-data.geo_us_boundaries.counties` c
  ON c.geo_id = p.geoid
ORDER BY pct_increase DESC
LIMIT 1;