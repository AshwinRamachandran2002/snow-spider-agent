-- Most prescribed (highest total claim count) medication in each U.S. state for year 2014
WITH state_drug_totals AS (
  SELECT
    nppes_provider_state                   AS state,
    UPPER(drug_name)                       AS drug_name,
    SUM(CAST(total_claim_count AS INT64))  AS total_claims
  FROM
    `bigquery-public-data.cms_medicare.part_d_prescriber_2014`
  WHERE
    nppes_provider_state IS NOT NULL        -- keep valid state rows
  GROUP BY
    state,
    drug_name
),
ranked_drugs AS (
  SELECT
    state,
    drug_name,
    total_claims,
    ROW_NUMBER() OVER (
      PARTITION BY state
      ORDER BY total_claims DESC, drug_name  -- tie‑breaker: alphabetically
    ) AS rn
  FROM
    state_drug_totals
)
SELECT
  state,
  drug_name,
  total_claims
FROM
  ranked_drugs
WHERE
  rn = 1          -- top drug per state
ORDER BY
  state;