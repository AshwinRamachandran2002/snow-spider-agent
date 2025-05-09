WITH banks_filtered AS (
  SELECT
    state_name,
    COALESCE(total_assets, 0) AS assets
  FROM
    `bigquery-public-data.fdic_banks.institutions`
  WHERE
    established_date BETWEEN '1900-01-01' AND '2000-12-31'
    AND LOWER(institution_name) LIKE 'bank%'
),
state_asset_totals AS (
  SELECT
    state_name,
    SUM(assets) AS sum_assets
  FROM
    banks_filtered
  GROUP BY
    state_name
),
top_state AS (
  SELECT
    state_name
  FROM
    state_asset_totals
  ORDER BY
    sum_assets DESC
  LIMIT 1
)
SELECT
  COUNT(*) AS total_banking_institutions
FROM
  `bigquery-public-data.fdic_banks.institutions`
WHERE
  state_name = (SELECT state_name FROM top_state);