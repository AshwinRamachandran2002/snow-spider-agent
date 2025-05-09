-- 1) Find the drug with the largest total claim count in New York (NY) for 2014
WITH top_ny_drug AS (
  SELECT
    drug_name,
    SUM(total_claim_count) AS ny_total_claims
  FROM `bigquery-public-data.cms_medicare.part_d_prescriber_2014`
  WHERE nppes_provider_state = 'NY'
  GROUP BY drug_name
  ORDER BY ny_total_claims DESC
  LIMIT 1        -- <-- highest‑volume drug in NY
)

-- 2) For that drug, list the five states with the greatest claim counts,
--    including their total claim counts and drug costs
SELECT
  p.nppes_provider_state           AS state,
  SUM(p.total_claim_count)  AS total_claims,
  SUM(p.total_drug_cost)    AS total_drug_cost
FROM `bigquery-public-data.cms_medicare.part_d_prescriber_2014` AS p
JOIN top_ny_drug AS d
  ON p.drug_name = d.drug_name
WHERE p.nppes_provider_state IS NOT NULL
GROUP BY state
ORDER BY total_claims DESC
LIMIT 5;