-- Most prescribed medication (by claim count) in every U.S. state for 2014
SELECT
  nppes_provider_state                         AS state,
  drug_name                                    AS most_prescribed_drug,
  SUM(total_claim_count)                       AS total_claims_2014
FROM `bigquery-public-data.cms_medicare.part_d_prescriber_2014`
GROUP BY
  nppes_provider_state,
  drug_name
QUALIFY
  ROW_NUMBER() OVER (
    PARTITION BY nppes_provider_state
    ORDER BY SUM(total_claim_count) DESC
  ) = 1
ORDER BY
  state;