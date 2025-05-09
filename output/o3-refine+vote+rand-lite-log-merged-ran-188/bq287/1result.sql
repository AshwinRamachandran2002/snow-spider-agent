/*  Employment-rate (16+ population) for the Utah ZIP code(s) that have the
    fewest FDIC-insured bank locations, using 2017 ACS 5-year estimates          */

WITH fdic_branches AS (          -- count FDIC locations per Utah ZIP
  SELECT
    zip_code,
    COUNT(*) AS branch_cnt
  FROM `bigquery-public-data.fdic_banks.locations`
  WHERE state = 'UT'
  GROUP BY zip_code
),
min_branch_zip AS (              -- ZIP code(s) with the fewest branches
  SELECT
    zip_code
  FROM fdic_branches
  WHERE branch_cnt = (SELECT MIN(branch_cnt) FROM fdic_branches)
),
acs_employment AS (              -- 2017 ACS employment-rate per ZIP
  SELECT
    RIGHT(geo_id, 5) AS zip_code,
    SAFE_DIVIDE(employed_pop, employed_pop + unemployed_pop) AS employment_rate
  FROM `bigquery-public-data.census_bureau_acs.zip_codes_2017_5yr`
)
SELECT
  z.zip_code,
  ROUND(a.employment_rate * 100, 2) AS employment_rate_percent_2017
FROM min_branch_zip AS z
LEFT JOIN acs_employment AS a
       ON a.zip_code = z.zip_code;