WITH ny_drug_totals AS (
  -- Total prescriptions by drug within New York
  SELECT
    drug_name,
    SUM(total_claim_count) AS total_claims
  FROM `bigquery-public-data.cms_medicare.part_d_prescriber_2014`
  WHERE nppes_provider_state = 'NY'
  GROUP BY drug_name
),
top_drug AS (
  -- Drug with the highest number of NY prescriptions
  SELECT drug_name
  FROM ny_drug_totals
  ORDER BY total_claims DESC
  LIMIT 1
),
drug_state_totals AS (
  -- Aggregate totals for that drug across all states
  SELECT
    nppes_provider_state AS state,
    SUM(total_claim_count)  AS total_claims,
    SUM(total_drug_cost)    AS total_drug_cost
  FROM `bigquery-public-data.cms_medicare.part_d_prescriber_2014`
  WHERE drug_name = (SELECT drug_name FROM top_drug)
  GROUP BY state
)
-- Top‑5 states by claim count for the identified drug
SELECT
  state,
  total_claims,
  total_drug_cost
FROM drug_state_totals
ORDER BY total_claims DESC
LIMIT 5;