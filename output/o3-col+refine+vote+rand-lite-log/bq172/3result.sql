-- Top 5 states by claim counts for the single most-prescribed drug in NY (2014)
WITH top_ny_drug AS (
  SELECT
    `drug_name`
  FROM `bigquery-public-data.cms_medicare.part_d_prescriber_2014`
  WHERE `nppes_provider_state` = 'NY'
  GROUP BY `drug_name`
  ORDER BY SUM(`total_claim_count`) DESC
  LIMIT 1            -- the drug with the most NY prescriptions
)
SELECT
  d.`nppes_provider_state`          AS state,
  SUM(d.`total_claim_count`)        AS total_claims,
  SUM(d.`total_drug_cost`)          AS total_drug_cost
FROM `bigquery-public-data.cms_medicare.part_d_prescriber_2014` AS d
JOIN top_ny_drug t
  ON d.`drug_name` = t.`drug_name`
GROUP BY state
ORDER BY total_claims DESC
LIMIT 5;