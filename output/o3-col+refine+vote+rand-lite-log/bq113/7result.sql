-- Utah county with the greatest % increase in construction employment (2000 → 2018)
WITH year_avgs AS (
  -- Average 3rd-month construction employment for each Utah county in 2000
  SELECT
    geoid,
    AVG(month3_emplvl_23_construction) AS avg_empl,
    2000 AS yr
  FROM `bigquery-public-data.bls_qcew.2000_q*`
  WHERE LEFT(geoid,2) = '49'                          -- Utah counties only
  GROUP BY geoid
  
  UNION ALL
  
  -- Same average for 2018
  SELECT
    geoid,
    AVG(month3_emplvl_23_construction) AS avg_empl,
    2018 AS yr
  FROM `bigquery-public-data.bls_qcew.2018_q*`
  WHERE LEFT(geoid,2) = '49'
  GROUP BY geoid
),
pivot AS (
  SELECT
    geoid,
    MAX(IF(yr = 2000, avg_empl, NULL)) AS avg_2000,
    MAX(IF(yr = 2018, avg_empl, NULL)) AS avg_2018
  FROM year_avgs
  GROUP BY geoid
),
pct_change AS (
  SELECT
    geoid,
    SAFE_DIVIDE(avg_2018 - avg_2000, avg_2000) * 100 AS pct_increase
  FROM pivot
)
SELECT
  c.county_name    AS utah_county,
  ROUND(p.pct_increase, 2) AS pct_increase
FROM pct_change p
JOIN `bigquery-public-data.geo_us_boundaries.counties` AS c
  ON c.geo_id = p.geoid
ORDER BY pct_increase DESC
LIMIT 1;