-- 1) Find the drug with the greatest number of claims in New York (2014)
WITH ny_totals AS (
  SELECT
    drug_name,
    SUM(total_claim_count) AS ny_claims
  FROM `bigquery-public-data.cms_medicare.part_d_prescriber_2014`
  WHERE nppes_provider_state = 'NY'
  GROUP BY drug_name
),
top_drug AS (
  SELECT drug_name
  FROM ny_totals
  ORDER BY ny_claims DESC
  LIMIT 1
),

-- 2) For that drug, aggregate claim counts and costs by state
state_totals AS (
  SELECT
    nppes_provider_state AS state,
    SUM(total_claim_count) AS total_claims,
    SUM(total_drug_cost)  AS total_cost
  FROM `bigquery-public-data.cms_medicare.part_d_prescriber_2014`
  WHERE drug_name IN (SELECT drug_name FROM top_drug)
  GROUP BY state
)

-- 3) Return the five states with the highest claim counts
SELECT
  state,
  total_claims,
  total_cost
FROM state_totals
WHERE state IS NOT NULL
ORDER BY total_claims DESC
LIMIT 5;