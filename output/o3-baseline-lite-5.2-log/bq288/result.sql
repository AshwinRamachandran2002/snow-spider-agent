WITH filtered_banks AS (
  -- Banks established in the target period whose names start with 'Bank'
  SELECT
    state_name,
    COALESCE(total_assets, 0) AS total_assets
  FROM
    `bigquery-public-data.fdic_banks.institutions`
  WHERE
    LOWER(institution_name) LIKE 'bank%'                      -- name starts with 'Bank'
    AND established_date BETWEEN '1900-01-01' AND '2000-12-31' -- establishment window
),
state_asset_totals AS (
  -- Sum assets for each state
  SELECT
    state_name,
    SUM(total_assets) AS assets_sum
  FROM
    filtered_banks
  GROUP BY
    state_name
),
top_state AS (
  -- State with the highest summed assets
  SELECT
    state_name
  FROM
    state_asset_totals
  ORDER BY
    assets_sum DESC
  LIMIT 1
)
-- Count ALL banking institutions (no filters) located in that top‑assets state
SELECT
  COUNT(*) AS total_institutions
FROM
  `bigquery-public-data.fdic_banks.institutions`
WHERE
  state_name = (SELECT state_name FROM top_state);