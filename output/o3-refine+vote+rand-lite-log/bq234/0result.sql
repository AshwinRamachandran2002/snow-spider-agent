-- Most prescribed medication (highest number of Medicare Part‑D claims) in each U.S. state, CY 2014
WITH state_drug_totals AS (
  SELECT
    nppes_provider_state AS state_code,
    COALESCE(generic_name, drug_name) AS medication,       -- prefer generic when available
    SUM(total_claim_count) AS total_claims                 -- aggregate across all prescribers
  FROM
    `bigquery-public-data.cms_medicare.part_d_prescriber_2014`
  GROUP BY
    state_code,
    medication
),
ranked_medications AS (
  SELECT
    state_code,
    medication,
    total_claims,
    ROW_NUMBER() OVER (
      PARTITION BY state_code
      ORDER BY total_claims DESC, medication                -- tie‑breaker: alphabetical
    ) AS rn
  FROM
    state_drug_totals
)
SELECT
  state_code,
  medication AS most_prescribed_medication,
  total_claims
FROM
  ranked_medications
WHERE
  rn = 1
ORDER BY
  state_code;