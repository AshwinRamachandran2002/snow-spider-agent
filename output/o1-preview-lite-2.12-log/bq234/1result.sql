SELECT
  `nppes_provider_state` AS State,
  `drug_name` AS Drug_Name
FROM (
  SELECT
    `nppes_provider_state`,
    `drug_name`,
    SUM(`total_claim_count`) AS total_claims,
    ROW_NUMBER() OVER (
      PARTITION BY `nppes_provider_state`
      ORDER BY SUM(`total_claim_count`) DESC
    ) AS rn
  FROM `bigquery-public-data.cms_medicare.part_d_prescriber_2014`
  GROUP BY `nppes_provider_state`, `drug_name`
)
WHERE rn = 1
ORDER BY State;