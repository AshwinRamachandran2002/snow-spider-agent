WITH bank_assets_by_state AS (
  -- 1.  Sum assets of banks whose names start with 'Bank', established between 1900‑01‑01 and 2000‑12‑31
  SELECT
    state                                    AS state_code,
    SUM(COALESCE(total_assets,0))            AS total_assets_state
  FROM
    `bigquery-public-data.fdic_banks.institutions`
  WHERE
    LOWER(institution_name) LIKE 'bank%'                 -- name starts with 'Bank'
    AND established_date BETWEEN '1900-01-01' AND '2000-12-31'
  GROUP BY
    state_code
),
top_state AS (
  -- 2.  State with the greatest summed assets
  SELECT state_code
  FROM bank_assets_by_state
  ORDER BY total_assets_state DESC
  LIMIT 1
)

-- 3.  Count *all* banking institutions (no additional filters) in that state
SELECT
  t.state_code                           AS state,
  COUNT(*)                               AS total_institutions
FROM
  `bigquery-public-data.fdic_banks.institutions` i
JOIN
  top_state t
ON
  i.state = t.state_code
GROUP BY
  t.state_code;