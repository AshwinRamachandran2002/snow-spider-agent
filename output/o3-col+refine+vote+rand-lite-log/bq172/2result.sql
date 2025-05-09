WITH top_ny_drug AS (
  -- Identify the single drug with the highest total prescriptions in New York
  SELECT
    `drug_name`
  FROM `bigquery-public-data.cms_medicare.part_d_prescriber_2014`
  WHERE `nppes_provider_state` = 'NY'
  GROUP BY `drug_name`
  ORDER BY SUM(`total_claim_count`) DESC
  LIMIT 1
),
state_totals AS (
  -- Aggregate claim counts and costs for that drug across all states
  SELECT
    p.`nppes_provider_state` AS state,
    SUM(p.`total_claim_count`) AS total_claims,
    SUM(p.`total_drug_cost`)   AS total_cost
  FROM `bigquery-public-data.cms_medicare.part_d_prescriber_2014` AS p
  JOIN top_ny_drug t
    ON p.`drug_name` = t.`drug_name`
  GROUP BY state
)
-- Return the five states with the highest claim counts for the top NY drug
SELECT
  state,
  total_claims,
  total_cost
FROM state_totals
ORDER BY total_claims DESC
LIMIT 5;