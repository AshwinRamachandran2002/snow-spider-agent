-- 1) Find the drug with the greatest total number of prescriptions written by prescribers
--    whose practice state is New York (NY) in 2014.
-- 2) For that drug, list the five states with the largest total claim counts,
--    together with their overall claim counts and overall drug costs.

WITH ny_drug_totals AS (
  SELECT
    drug_name,
    SUM(total_claim_count) AS ny_total_claims
  FROM `bigquery-public-data.cms_medicare.part_d_prescriber_2014`
  WHERE nppes_provider_state = 'NY'
  GROUP BY drug_name
),
top_ny_drug AS (
  SELECT drug_name
  FROM ny_drug_totals
  ORDER BY ny_total_claims DESC, drug_name          -- tie‑breaker on name, if any
  LIMIT 1                                           -- single highest‑volume drug in NY
),
state_claims_for_top_drug AS (
  SELECT
    nppes_provider_state        AS state,
    SUM(total_claim_count)      AS total_claims,
    SUM(total_drug_cost)        AS total_drug_cost
  FROM `bigquery-public-data.cms_medicare.part_d_prescriber_2014`
  WHERE drug_name = (SELECT drug_name FROM top_ny_drug)
    AND nppes_provider_state IS NOT NULL
    AND nppes_provider_state <> ''
  GROUP BY state
)
SELECT
  state,
  total_claims,
  total_drug_cost
FROM state_claims_for_top_drug
ORDER BY total_claims DESC
LIMIT 5;