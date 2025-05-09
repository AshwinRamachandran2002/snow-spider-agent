WITH state_asset_totals AS (
  -- Sum total assets for qualifying banks in each state
  SELECT
    state,
    SUM(total_assets) AS sum_assets
  FROM `bigquery-public-data.fdic_banks.institutions`
  WHERE LOWER(institution_name) LIKE 'bank%'                 -- name starts with 'Bank'
    AND established_date BETWEEN '1900-01-01' AND '2000-12-31'
    AND total_assets IS NOT NULL
  GROUP BY state
),
top_state AS (
  -- Identify the state with the highest summed assets
  SELECT state
  FROM (
    SELECT
      state,
      RANK() OVER (ORDER BY sum_assets DESC) AS rnk
    FROM state_asset_totals
  )
  WHERE rnk = 1
)
-- Count ALL institutions (no filters) located in that top state
SELECT
  COUNT(*) AS total_institutions
FROM `bigquery-public-data.fdic_banks.institutions`
WHERE state IN (SELECT state FROM top_state);