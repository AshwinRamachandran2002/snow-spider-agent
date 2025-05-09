WITH state_generic_totals AS (
  SELECT
    `nppes_provider_state` AS state,
    `generic_name`,
    SUM(`total_claim_count`) AS total_claims
  FROM
    `bigquery-public-data.cms_medicare.part_d_prescriber_2014`
  WHERE
    `generic_name` IS NOT NULL
  GROUP BY
    state,
    `generic_name`
),
ranked AS (
  SELECT
    state,
    `generic_name`,
    total_claims,
    ROW_NUMBER() OVER (
      PARTITION BY state
      ORDER BY total_claims DESC, `generic_name`
    ) AS rn
  FROM
    state_generic_totals
)
SELECT
  state,
  `generic_name` AS most_prescribed_medication_2014
FROM
  ranked
WHERE
  rn = 1
ORDER BY
  state;