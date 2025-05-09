-- count of banking institutions in the state whose filtered banks
-- (established 1900‑01‑01 to 2000‑12‑31 and name starts with 'Bank')
-- have the greatest total assets
WITH filtered AS (
  SELECT
    state_name,
    state AS state_code,
    COALESCE(total_assets, 0) AS total_assets
  FROM
    `bigquery-public-data.fdic_banks.institutions`
  WHERE
    established_date BETWEEN '1900-01-01' AND '2000-12-31'
    AND LOWER(institution_name) LIKE 'bank%'            -- names starting with 'Bank'
),
state_sums AS (
  SELECT
    state_name,
    state_code,
    SUM(total_assets) AS sum_assets,
    COUNT(*) AS institution_cnt
  FROM filtered
  GROUP BY state_name, state_code
),
top_state AS (
  SELECT
    state_name,
    state_code,
    institution_cnt,
    ROW_NUMBER() OVER (ORDER BY sum_assets DESC) AS rn
  FROM state_sums
)
SELECT
  institution_cnt AS total_institutions_in_top_state
FROM
  top_state
WHERE
  rn = 1;