-- 1) Identify the single drug with the greatest number of 2014 Medicare Part‑D prescriptions in New York  
-- 2) For that drug, list the five states with the largest total claim counts, along with their
--    overall claim counts and total drug costs (2014)

WITH ny_drug_totals AS (
  SELECT
    drug_name,
    SUM(total_claim_count) AS ny_total_claims
  FROM `bigquery-public-data.cms_medicare.part_d_prescriber_2014`
  WHERE nppes_provider_state = 'NY'
  GROUP BY drug_name
),
top_drug AS (          -- highest‑volume drug in NY
  SELECT drug_name
  FROM ny_drug_totals
  ORDER BY ny_total_claims DESC
  LIMIT 1
),
state_totals AS (      -- state‑level totals for that drug nationwide
  SELECT
    nppes_provider_state AS state,
    SUM(total_claim_count)  AS total_claims,
    SUM(total_drug_cost)    AS total_drug_cost
  FROM `bigquery-public-data.cms_medicare.part_d_prescriber_2014`
  WHERE drug_name = (SELECT drug_name FROM top_drug)
    AND nppes_provider_state IS NOT NULL
    AND nppes_provider_state != ''
  GROUP BY state
)
SELECT
  state,
  total_claims,
  total_drug_cost
FROM state_totals
ORDER BY total_claims DESC
LIMIT 5;