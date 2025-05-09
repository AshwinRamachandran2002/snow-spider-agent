WITH state_drug_totals AS (
  -- total 2014 Part‑D claims by drug within each state
  SELECT
    nppes_provider_state                          AS state,
    UPPER(drug_name)                              AS drug_name,
    SUM(total_claim_count)                        AS total_claims
  FROM `bigquery-public-data.cms_medicare.part_d_prescriber_2014`
  GROUP BY state, drug_name
),
state_top_drug AS (
  -- rank drugs by total claims per state
  SELECT
    state,
    drug_name,
    total_claims,
    ROW_NUMBER() OVER (
      PARTITION BY state 
      ORDER BY total_claims DESC, drug_name ASC   -- tiebreaker: alphabetically
    ) AS rn
  FROM state_drug_totals
)
SELECT
  state,
  drug_name                 AS most_prescribed_medication,
  total_claims
FROM state_top_drug
WHERE rn = 1
ORDER BY state;