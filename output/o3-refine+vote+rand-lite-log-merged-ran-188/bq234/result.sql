-- Most prescribed medication in each U.S. state for calendar year 2014
WITH drug_totals AS (
  SELECT
    nppes_provider_state                             AS state,
    UPPER(drug_name)                                 AS drug_name,
    SUM(COALESCE(total_claim_count,0))               AS total_claims
  FROM `bigquery-public-data.cms_medicare.part_d_prescriber_2014`
  -- keep only 2‑letter state abbreviations (excludes territories/blank/nulls)
  WHERE REGEXP_CONTAINS(nppes_provider_state, r'^[A-Z]{2}$')
  GROUP BY state, drug_name
),
ranked AS (
  SELECT
    state,
    drug_name,
    total_claims,
    ROW_NUMBER() OVER (PARTITION BY state 
                       ORDER BY total_claims DESC, drug_name) AS rn
  FROM drug_totals
)
SELECT
  state,
  drug_name       AS most_prescribed_medication,
  total_claims    AS prescriptions_2014
FROM ranked
WHERE rn = 1
ORDER BY state;