WITH bank_1900_2000 AS (
  -- Sum assets for banks founded 1900-01-01 – 2000-12-31 whose names start with 'Bank'
  SELECT
    state,
    SUM(COALESCE(total_assets, 0)) AS sum_assets
  FROM `bigquery-public-data.fdic_banks.institutions`
  WHERE established_date BETWEEN '1900-01-01' AND '2000-12-31'
    AND LOWER(institution_name) LIKE 'bank%'
  GROUP BY state
),
top_state AS (
  -- Identify the single state with the highest summed assets
  SELECT state
  FROM bank_1900_2000
  ORDER BY sum_assets DESC
  LIMIT 1
)
-- Count ALL banking institutions (no filters) in that top-asset state
SELECT
  state,
  COUNT(DISTINCT fdic_certificate_number) AS total_institutions
FROM `bigquery-public-data.fdic_banks.institutions`
WHERE state IN (SELECT state FROM top_state)
GROUP BY state;