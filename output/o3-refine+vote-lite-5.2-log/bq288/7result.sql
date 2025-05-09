WITH filtered_banks AS (
  -- Banks that start with 'Bank' and were established between 1900‑01‑01 and 2000‑12‑31
  SELECT
    state,                     -- two–letter postal code
    SUM(total_assets) AS state_assets
  FROM `bigquery-public-data.fdic_banks.institutions`
  WHERE
    LOWER(institution_name) LIKE 'bank%'                               -- name starts with “Bank”
    AND established_date BETWEEN '1900-01-01' AND '2000-12-31'         -- establishment window
    AND total_assets IS NOT NULL
  GROUP BY state
),
top_state AS (
  -- State with the largest summed assets for the filtered banks
  SELECT state
  FROM filtered_banks
  ORDER BY state_assets DESC
  LIMIT 1
)
-- Total number of ALL institutions (no filters) located in that state
SELECT COUNT(*) AS total_institutions
FROM `bigquery-public-data.fdic_banks.institutions`
WHERE state = (SELECT state FROM top_state);