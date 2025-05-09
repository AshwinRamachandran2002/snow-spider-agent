WITH condition_acres AS (
  SELECT
    p.evaluation_group,
    p.evaluation_type,
    c.condition_status_code,
    p.evaluation_description,
    p.state_code,

    -- macro‑plot acres
    ROUND(
      COALESCE(p.expansion_factor, 0) *
      COALESCE(p.adjustment_factor_for_the_macroplot, 1) *
      COALESCE(c.macroplot_proportion_unadjusted, 0),
      4
    ) AS macroplot_acres,

    -- sub‑plot acres
    ROUND(
      COALESCE(p.expansion_factor, 0) *
      COALESCE(p.adjustment_factor_for_the_subplot, 1) *
      COALESCE(c.subplot_proportion_unadjusted, 0),
      4
    ) AS subplot_acres,

    ROW_NUMBER() OVER (
      PARTITION BY p.evaluation_group
      ORDER BY COALESCE(p.expansion_factor, 0) *
               COALESCE(p.adjustment_factor_for_the_subplot, 1) *
               COALESCE(c.subplot_proportion_unadjusted, 0) DESC
    ) AS rn
  FROM `bigquery-public-data.usfs_fia.population`  AS p
  JOIN `bigquery-public-data.usfs_fia.condition`   AS c
    ON p.plot_sequence_number = c.plot_sequence_number
  -- keep only evaluation groups for the year 2012
  WHERE MOD(p.evaluation_group, 10000) = 2012
)

SELECT
  evaluation_group,
  evaluation_type,
  condition_status_code,
  evaluation_description,
  state_code,
  macroplot_acres,
  subplot_acres
FROM condition_acres
WHERE rn = 1
ORDER BY subplot_acres DESC
LIMIT 10;