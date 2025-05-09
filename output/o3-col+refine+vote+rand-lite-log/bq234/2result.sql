-- Most prescribed medication in each U.S. state for calendar year 2014
SELECT
  nppes_provider_state AS state,
  drug_name            AS most_prescribed_drug,
  SUM(total_claim_count) AS total_claims
FROM `bigquery-public-data.cms_medicare.part_d_prescriber_2014`
GROUP BY state, drug_name
QUALIFY ROW_NUMBER() OVER (
          PARTITION BY state
          ORDER BY SUM(total_claim_count) DESC
        ) = 1
ORDER BY state;