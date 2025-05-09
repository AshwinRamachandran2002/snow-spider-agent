-- 1) Find the drug (generic name) with the greatest number of prescriptions in New York in 2014
-- 2) For that drug, aggregate claim counts and costs across all states
-- 3) Return the five states with the highest claim counts
WITH ny_drug_totals AS (
  SELECT
    generic_name,
    SUM(total_claim_count) AS ny_total_claims
  FROM `bigquery-public-data.cms_medicare.part_d_prescriber_2014`
  WHERE nppes_provider_state = 'NY'
  GROUP BY generic_name
),
top_ny_drug AS (
  SELECT generic_name
  FROM ny_drug_totals
  ORDER BY ny_total_claims DESC
  LIMIT 1
),
state_totals AS (
  SELECT
    nppes_provider_state AS state,
    SUM(total_claim_count)  AS total_claims,
    SUM(total_drug_cost)    AS total_drug_cost
  FROM `bigquery-public-data.cms_medicare.part_d_prescriber_2014`
  WHERE generic_name IN (SELECT generic_name FROM top_ny_drug)
  GROUP BY state
)
SELECT
  state,
  total_claims,
  total_drug_cost
FROM state_totals
WHERE state IS NOT NULL
ORDER BY total_claims DESC, state
LIMIT 5;