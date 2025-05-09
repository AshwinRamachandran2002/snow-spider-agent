-- total number of FDIC‑certified banking institutions located in the
-- state whose “Bank …” institutions (founded 1900‑2000) have the
-- largest combined assets
WITH bank_subset AS (
  SELECT
    state,
    total_assets
  FROM `bigquery-public-data.fdic_banks.institutions`
  WHERE LOWER(institution_name) LIKE 'bank %'
    AND established_date BETWEEN '1900-01-01' AND '2000-12-31'
),
ranked_states AS (
  SELECT
    state,
    SUM(total_assets) AS sum_assets,
    RANK() OVER (ORDER BY SUM(total_assets) DESC) AS rnk
  FROM bank_subset
  GROUP BY state
),
top_state AS (
  SELECT state
  FROM ranked_states
  WHERE rnk = 1
)
SELECT
  ts.state                         AS state_code,
  COUNT(DISTINCT i.fdic_certificate_number) AS total_institutions
FROM top_state ts
JOIN `bigquery-public-data.fdic_banks.institutions` i
  ON i.state = ts.state
GROUP BY state_code;