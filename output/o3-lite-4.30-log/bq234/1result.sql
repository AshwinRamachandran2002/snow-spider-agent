WITH ranked AS (
  SELECT
    nppes_provider_state AS state,
    drug_name,
    SUM(total_claim_count) AS total_claims,
    RANK() OVER (
      PARTITION BY nppes_provider_state
      ORDER BY SUM(total_claim_count) DESC
    ) AS rnk
  FROM `bigquery-public-data.cms_medicare.part_d_prescriber_2014`
  WHERE drug_name IS NOT NULL
    AND total_claim_count IS NOT NULL
    AND nppes_provider_state NOT IN ('AA','AE','AP','AS','GU','MP','PR','VI','XX','ZZ')
  GROUP BY state, drug_name
)
SELECT
  state,
  drug_name AS most_prescribed_medication_2014
FROM ranked
WHERE rnk = 1
ORDER BY state;