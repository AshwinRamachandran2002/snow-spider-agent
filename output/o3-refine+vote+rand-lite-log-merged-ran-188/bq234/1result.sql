-- Most prescribed medication (by total Medicare Part D claim count) in each U.S. state, CY 2014
WITH state_drug_totals AS (
  SELECT
    nppes_provider_state                                    AS state,
    COALESCE(generic_name, drug_name)                       AS medication,
    SUM(total_claim_count)                                  AS total_claims
  FROM
    `bigquery-public-data.cms_medicare.part_d_prescriber_2014`
  WHERE
    nppes_provider_state IS NOT NULL                -- keep valid states
    AND LENGTH(nppes_provider_state) = 2            -- exclude territories/unknowns coded differently
  GROUP BY
    state, medication
),
ranked AS (
  SELECT
    state,
    medication,
    total_claims,
    ROW_NUMBER() OVER (PARTITION BY state
                       ORDER BY total_claims DESC, medication) AS rn
  FROM
    state_drug_totals
)
SELECT
  state,
  medication            AS most_prescribed_medication,
  total_claims
FROM
  ranked
WHERE
  rn = 1                 -- keep the top‑ranked medication per state
ORDER BY
  state;