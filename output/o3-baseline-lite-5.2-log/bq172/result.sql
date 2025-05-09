WITH ny_claims AS (
  -- 1.  Prescriptions filled by NY providers, summed by drug
  SELECT
    drug_name,
    SUM(total_claim_count) AS ny_total_claims
  FROM
    `bigquery-public-data.cms_medicare.part_d_prescriber_2014`
  WHERE
    nppes_provider_state = 'NY'
  GROUP BY
    drug_name
),
top_drug AS (
  -- 2.  Drug with the most NY prescriptions in 2014
  SELECT
    drug_name
  FROM
    ny_claims
  ORDER BY
    ny_total_claims DESC,
    drug_name          -- tie‑breaker
  LIMIT 1
),
state_totals AS (
  -- 3.  State‑level totals for that drug
  SELECT
    nppes_provider_state AS state,
    SUM(total_claim_count) AS total_claims,
    SUM(total_drug_cost)  AS total_drug_cost
  FROM
    `bigquery-public-data.cms_medicare.part_d_prescriber_2014`
  WHERE
    drug_name = (SELECT drug_name FROM top_drug)
    AND nppes_provider_state IS NOT NULL
  GROUP BY
    state
)
-- 4.  Top five states by claim count
SELECT
  state,
  total_claims,
  total_drug_cost
FROM
  state_totals
ORDER BY
  total_claims DESC
LIMIT 5;