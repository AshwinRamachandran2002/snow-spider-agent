WITH state_drug_totals AS (
  SELECT
    nppes_provider_state AS state,
    drug_name,
    SUM(total_claim_count) AS total_claims
  FROM `bigquery-public-data.cms_medicare.part_d_prescriber_2014`
  GROUP BY state, drug_name
),
ranked AS (
  SELECT
    state,
    drug_name,
    total_claims,
    ROW_NUMBER() OVER (PARTITION BY state ORDER BY total_claims DESC, drug_name) AS rn
  FROM state_drug_totals
)
SELECT
  state,
  drug_name AS most_prescribed_drug,
  total_claims
FROM ranked
WHERE rn = 1
ORDER BY state;