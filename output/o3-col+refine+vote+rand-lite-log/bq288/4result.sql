WITH summed_assets AS (
  -- 1. Sum assets for banks whose names start with 'Bank' and were established in the target period
  SELECT
    state_name,
    SUM(COALESCE(total_assets, 0)) AS total_assets_1900_2000
  FROM `bigquery-public-data.fdic_banks.institutions`
  WHERE LOWER(institution_name) LIKE 'bank%'
    AND established_date BETWEEN '1900-01-01' AND '2000-12-31'
  GROUP BY state_name
),
top_state AS (
  -- 2. Identify the single state with the highest summed assets
  SELECT state_name
  FROM summed_assets
  ORDER BY total_assets_1900_2000 DESC
  LIMIT 1
)
-- 3. Count all banking institutions (no filters) in that top state
SELECT
  ts.state_name,
  COUNT(*) AS total_number_of_institutions
FROM `bigquery-public-data.fdic_banks.institutions` AS inst
JOIN top_state AS ts
  ON inst.state_name = ts.state_name
GROUP BY ts.state_name;