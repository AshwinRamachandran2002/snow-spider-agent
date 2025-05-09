WITH top_ny_drug AS (
  SELECT
    drug_name
  FROM `bigquery-public-data.cms_medicare.part_d_prescriber_2014`
  WHERE nppes_provider_state = 'NY'
  GROUP BY drug_name
  ORDER BY SUM(total_claim_count) DESC
  LIMIT 1
),
drug_claims_by_state AS (
  SELECT
    p.nppes_provider_state               AS state,
    SUM(p.total_claim_count)             AS total_claim_count,
    ROUND(SUM(p.total_drug_cost), 4)     AS total_drug_cost
  FROM `bigquery-public-data.cms_medicare.part_d_prescriber_2014` AS p
  JOIN top_ny_drug t
    ON p.drug_name = t.drug_name
  GROUP BY state
)
SELECT
  state,
  total_claim_count,
  total_drug_cost
FROM drug_claims_by_state
ORDER BY total_claim_count DESC
LIMIT 5;