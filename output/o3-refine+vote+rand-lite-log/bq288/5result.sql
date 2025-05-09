-- total number of banking institutions in the state whose
-- “Bank*” institutions (established 1900‑01‑01 to 2000‑12‑31)
-- have the greatest summed assets
WITH bank_1900_2000 AS (
  SELECT
    state,                                            -- two–letter state code
    COALESCE(total_assets, 0) AS total_assets
  FROM `bigquery-public-data.fdic_banks.institutions`
  WHERE
    LOWER(institution_name) LIKE 'bank%'              -- name starts with 'Bank'
    AND established_date BETWEEN '1900-01-01' AND '2000-12-31'
),

state_asset_sums AS (                                 -- sum assets per state
  SELECT
    state,
    SUM(total_assets) AS sum_assets
  FROM bank_1900_2000
  GROUP BY state
),

top_state AS (                                        -- state with highest sum
  SELECT state
  FROM state_asset_sums
  ORDER BY sum_assets DESC
  LIMIT 1
)

SELECT
  COUNT(*) AS total_institutions                      -- all institutions in that state
FROM `bigquery-public-data.fdic_banks.institutions`
WHERE state = (SELECT state FROM top_state);