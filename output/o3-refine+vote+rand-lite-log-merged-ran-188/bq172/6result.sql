-- 1) Identify the drug with the highest number of prescriptions in New York (2014)
WITH ny_top_drug AS (
  SELECT
    drug_name,
    SUM(total_claim_count) AS ny_total_claims
  FROM
    `bigquery-public-data.cms_medicare.part_d_prescriber_2014`
  WHERE
    nppes_provider_state = 'NY'
  GROUP BY
    drug_name
  ORDER BY
    ny_total_claims DESC
  LIMIT 1
)

-- 2) For that drug, find the five states with the largest claim counts
SELECT
  p.nppes_provider_state               AS state,
  SUM(p.total_claim_count)   AS total_claims,
  SUM(p.total_drug_cost)     AS total_drug_cost
FROM
  `bigquery-public-data.cms_medicare.part_d_prescriber_2014` AS p
JOIN
  ny_top_drug d
ON
  p.drug_name = d.drug_name
GROUP BY
  state
ORDER BY
  total_claims DESC
LIMIT 5;