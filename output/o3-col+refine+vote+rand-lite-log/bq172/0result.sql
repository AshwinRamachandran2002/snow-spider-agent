WITH ny_top_drug AS (
  -- 1. Find the single drug with the highest total claim count in New York
  SELECT drug_name
  FROM `bigquery-public-data.cms_medicare.part_d_prescriber_2014`
  WHERE nppes_provider_state = 'NY'
  GROUP BY drug_name
  ORDER BY SUM(total_claim_count) DESC
  LIMIT 1
)

-- 2. For that drug, list the five states with the largest claim totals
SELECT
  d.drug_name,
  t.nppes_provider_state AS state,
  SUM(t.total_claim_count) AS total_claims,
  SUM(t.total_drug_cost)   AS total_drug_cost
FROM `bigquery-public-data.cms_medicare.part_d_prescriber_2014` AS t
JOIN ny_top_drug AS d
  ON t.drug_name = d.drug_name
GROUP BY d.drug_name, t.nppes_provider_state
ORDER BY total_claims DESC
LIMIT 5;