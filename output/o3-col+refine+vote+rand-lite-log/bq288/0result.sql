WITH bank_assets_by_state AS (
  -- Sum assets of banks whose names start with 'Bank' and were established between 1900-01-01 and 2000-12-31
  SELECT
    state,
    SUM(IFNULL(total_assets, 0)) AS sum_assets
  FROM `bigquery-public-data.fdic_banks.institutions`
  WHERE
    LOWER(institution_name) LIKE 'bank%'           -- institution name begins with 'Bank'
    AND established_date BETWEEN DATE '1900-01-01' -- within the specified date range
                         AND DATE '2000-12-31'
  GROUP BY state
),
top_state AS (
  -- Identify the single state with the highest summed assets
  SELECT state
  FROM bank_assets_by_state
  ORDER BY sum_assets DESC
  LIMIT 1
)
-- Count ALL banking institutions (of any name or vintage) located in that state
SELECT
  COUNT(*) AS total_institutions_in_top_state
FROM `bigquery-public-data.fdic_banks.institutions`
WHERE state = (SELECT state FROM top_state);