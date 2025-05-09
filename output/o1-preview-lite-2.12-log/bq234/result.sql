SELECT
  state,
  drug_name
FROM (
  SELECT
    nppes_provider_state AS state,
    drug_name,
    SUM(total_claim_count) AS total_claims,
    RANK() OVER (PARTITION BY nppes_provider_state ORDER BY SUM(total_claim_count) DESC) AS rank
  FROM `bigquery-public-data.cms_medicare.part_d_prescriber_2014`
  GROUP BY state, drug_name
)
WHERE rank = 1
ORDER BY state;