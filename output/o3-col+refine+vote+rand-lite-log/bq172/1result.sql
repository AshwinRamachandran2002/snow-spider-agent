WITH top_ny_drug AS (
  -- Find the single drug with the highest total claim count in NY
  SELECT
    drug_name
  FROM `bigquery-public-data.cms_medicare.part_d_prescriber_2014`
  WHERE nppes_provider_state = 'NY'
  GROUP BY drug_name
  ORDER BY SUM(total_claim_count) DESC
  LIMIT 1
)

SELECT
  nppes_provider_state AS state,
  SUM(total_claim_count) AS total_claims,
  SUM(total_drug_cost)  AS total_cost
FROM `bigquery-public-data.cms_medicare.part_d_prescriber_2014`
WHERE drug_name = (SELECT drug_name FROM top_ny_drug)
GROUP BY state
ORDER BY total_claims DESC
LIMIT 5;