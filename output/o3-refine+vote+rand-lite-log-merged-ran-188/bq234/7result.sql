-- Most prescribed (highest claim count) medication in each U.S. state for 2014
WITH drug_totals AS (
  SELECT
    nppes_provider_state                    AS state,
    UPPER(drug_name)                        AS drug_name,   -- normalize case
    SUM(total_claim_count)                  AS total_claims
  FROM `bigquery-public-data.cms_medicare.part_d_prescriber_2014`
  WHERE total_claim_count IS NOT NULL
    AND nppes_provider_state IS NOT NULL
    AND REGEXP_CONTAINS(nppes_provider_state, r'^[A-Z]{2}$')   -- keep 2‑letter state codes
  GROUP BY state, drug_name
),
ranked AS (
  SELECT
    state,
    drug_name,
    total_claims,
    ROW_NUMBER() OVER (PARTITION BY state
                       ORDER BY total_claims DESC, drug_name) AS rn
  FROM drug_totals
)
SELECT
  state,
  drug_name        AS most_prescribed_medication,
  total_claims     AS total_claim_count_2014
FROM ranked
WHERE rn = 1        -- pick the top‑ranked drug per state
ORDER BY state;