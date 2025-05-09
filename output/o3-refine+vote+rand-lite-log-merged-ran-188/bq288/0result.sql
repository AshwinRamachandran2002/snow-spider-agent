WITH bank_assets AS (
  -- Banks established between 1900‑01‑01 and 2000‑12‑31 whose names start with “Bank”
  SELECT
    state,                         -- two–letter postal code
    state_name,
    COALESCE(total_assets, 0) AS total_assets
  FROM
    `bigquery-public-data.fdic_banks.institutions`
  WHERE
    established_date BETWEEN '1900-01-01' AND '2000-12-31'
    AND LOWER(institution_name) LIKE 'bank%'
),
state_asset_totals AS (
  -- Sum assets per state
  SELECT
    state,
    state_name,
    SUM(total_assets) AS asset_sum
  FROM bank_assets
  GROUP BY state, state_name
),
top_state AS (
  -- State with the highest summed assets
  SELECT
    state,
    state_name
  FROM state_asset_totals
  ORDER BY asset_sum DESC
  LIMIT 1
)
-- Count all banking institutions (any name, any date) located in that state
SELECT
  ts.state AS state_code,
  ts.state_name,
  COUNT(DISTINCT inst.fdic_certificate_number) AS total_institutions
FROM
  top_state ts
JOIN
  `bigquery-public-data.fdic_banks.institutions` inst
ON
  inst.state = ts.state
GROUP BY
  ts.state,
  ts.state_name;