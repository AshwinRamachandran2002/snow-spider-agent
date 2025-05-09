WITH top_drug AS (
  -- Drug with the highest total prescriptions in NY during 2014
  SELECT drug_name
  FROM (
    SELECT
      drug_name,
      SUM(total_claim_count) AS ny_total_claims
    FROM `bigquery-public-data.cms_medicare.part_d_prescriber_2014`
    WHERE nppes_provider_state = 'NY'
    GROUP BY drug_name
    ORDER BY ny_total_claims DESC
    LIMIT 1
  )
)
SELECT
  p.nppes_provider_state AS state,
  SUM(p.total_claim_count) AS total_claims,
  SUM(p.total_drug_cost)   AS total_cost
FROM `bigquery-public-data.cms_medicare.part_d_prescriber_2014` AS p
JOIN top_drug td
  ON LOWER(p.drug_name) = LOWER(td.drug_name)
GROUP BY state
ORDER BY total_claims DESC
LIMIT 5;