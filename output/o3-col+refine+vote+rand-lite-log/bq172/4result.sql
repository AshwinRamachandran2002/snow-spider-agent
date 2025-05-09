-- Top-NY drug, then five states with largest totals for that drug
WITH ny_top_drug AS (           -- step 1: NY’s highest-claim drug in 2014
  SELECT drug_name
  FROM `bigquery-public-data.cms_medicare.part_d_prescriber_2014`
  WHERE nppes_provider_state = 'NY'
  GROUP BY drug_name
  ORDER BY SUM(total_claim_count) DESC
  LIMIT 1
)
SELECT                       -- step 2: state-level totals for that drug
  d.drug_name                          AS drug_name,
  t.nppes_provider_state               AS state,
  SUM(t.total_claim_count) AS total_claims,
  SUM(t.total_drug_cost)   AS total_drug_cost
FROM `bigquery-public-data.cms_medicare.part_d_prescriber_2014` AS t
JOIN ny_top_drug d
  ON t.drug_name = d.drug_name
GROUP BY drug_name, state
ORDER BY total_claims DESC
LIMIT 5;