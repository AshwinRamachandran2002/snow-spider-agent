WITH bank_assets AS (
  -- Sum assets of banks whose names start with 'Bank' and were established in the given period
  SELECT
    state,
    SUM(COALESCE(total_assets, 0)) AS total_state_assets
  FROM `bigquery-public-data.fdic_banks.institutions`
  WHERE
    LOWER(institution_name) LIKE 'bank%'                      -- name starts with 'Bank'
    AND established_date BETWEEN '1900-01-01' AND '2000-12-31' -- established within range
  GROUP BY state
),
top_state AS (
  -- Identify the state with the highest summed assets
  SELECT state
  FROM bank_assets
  ORDER BY total_state_assets DESC
  LIMIT 1
)
-- Count **all** banking institutions (no other filters) in that top state
SELECT
  COUNT(*) AS total_institutions_in_top_state
FROM `bigquery-public-data.fdic_banks.institutions`
WHERE state = (SELECT state FROM top_state);