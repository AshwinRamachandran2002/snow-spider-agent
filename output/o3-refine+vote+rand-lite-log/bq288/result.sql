WITH banks_1900_2000 AS (
  SELECT
    state,
    COALESCE(total_assets, 0) AS total_assets
  FROM `bigquery-public-data.fdic_banks.institutions`
  WHERE
    established_date BETWEEN '1900-01-01' AND '2000-12-31'
    AND LOWER(institution_name) LIKE 'bank%'
),
state_asset_totals AS (
  SELECT
    state,
    SUM(total_assets) AS total_assets_sum
  FROM banks_1900_2000
  GROUP BY state
),
state_with_max_assets AS (
  SELECT
    state
  FROM state_asset_totals
  ORDER BY total_assets_sum DESC
  LIMIT 1
)
SELECT
  COUNT(*) AS total_institutions
FROM `bigquery-public-data.fdic_banks.institutions`
WHERE state = (SELECT state FROM state_with_max_assets);