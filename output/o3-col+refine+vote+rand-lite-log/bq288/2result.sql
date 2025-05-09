WITH bank_assets AS (
  -- 1. Sum assets for “Bank …” institutions (1900-2000) by state
  SELECT
    state,
    SUM(COALESCE(total_assets, 0)) AS summed_assets
  FROM `bigquery-public-data.fdic_banks.institutions`
  WHERE LOWER(institution_name) LIKE 'bank%'
    AND established_date BETWEEN '1900-01-01' AND '2000-12-31'
  GROUP BY state
),
top_state AS (
  -- 2. State with the highest summed assets
  SELECT state
  FROM bank_assets
  ORDER BY summed_assets DESC
  LIMIT 1
)
-- 3. Count ALL institutions located in that top state
SELECT
  i.state                 AS state_code,
  COUNT(*)                AS total_number_of_institutions
FROM `bigquery-public-data.fdic_banks.institutions` AS i
JOIN top_state t
ON i.state = t.state
GROUP BY i.state;