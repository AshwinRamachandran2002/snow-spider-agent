WITH state_drug_totals AS (
  -- Aggregate total Part‑D claims for every drug within each state
  SELECT
    nppes_provider_state               AS state,
    UPPER(drug_name)                   AS drug_name,      -- canonicalise name
    SUM(total_claim_count)             AS total_claims
  FROM `bigquery-public-data.cms_medicare.part_d_prescriber_2014`
  WHERE nppes_provider_state IS NOT NULL
    AND total_claim_count  IS NOT NULL
  GROUP BY state, drug_name
),
state_top_drug AS (
  -- Rank drugs inside each state by total claims
  SELECT
    state,
    drug_name,
    total_claims,
    ROW_NUMBER() OVER (PARTITION BY state
                       ORDER BY total_claims DESC, drug_name) AS rn
  FROM state_drug_totals
)
SELECT
  state,
  drug_name            AS most_prescribed_medication,
  total_claims         AS claims_2014
FROM state_top_drug
WHERE rn = 1          -- keep only the highest‑claim drug per state
ORDER BY state;