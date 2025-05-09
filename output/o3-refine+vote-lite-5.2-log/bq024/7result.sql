-- Top 10 evaluation groups (year 2012) ranked by the single condition
-- having the largest subplot‑level acres inside each group
WITH cond_pop AS (
  SELECT
    p.evaluation_group,                         -- evaluation group id
    p.evaluation_type,                          -- evaluation type (e.g. EXPCURR, EXPVOL …)
    p.evaluation_description,                   -- text description of the evaluation
    p.state_code,                               -- state the evaluation applies to
    c.condition_status_code,                    -- status of the condition (1 = accessible forest, etc.)
    -- convert proportions / adjustment factors to acres
    p.expansion_factor *
    p.adjustment_factor_for_the_macroplot *
    c.macroplot_proportion_unadjusted           AS macroplot_acres,
    
    p.expansion_factor *
    p.adjustment_factor_for_the_subplot *
    c.subplot_proportion_unadjusted             AS subplot_acres
  FROM  `bigquery-public-data.usfs_fia.population` AS p
  JOIN  `bigquery-public-data.usfs_fia.condition`  AS c
        ON  p.plot_sequence_number = c.plot_sequence_number
        AND p.inventory_year      = c.inventory_year
  WHERE c.inventory_year = 2012                 -- restrict to 2012 inventory year
)
, best_cond_per_group AS (
  SELECT *
  FROM  (
    SELECT
      evaluation_group,
      evaluation_type,
      condition_status_code,
      evaluation_description,
      state_code,
      macroplot_acres,
      subplot_acres,
      ROW_NUMBER() OVER (
        PARTITION BY evaluation_group
        ORDER BY     subplot_acres DESC           -- biggest subplot acres first
      ) AS rn
    FROM cond_pop
  )
  WHERE rn = 1                                   -- keep only the single best condition per group
)
SELECT
  evaluation_group,
  evaluation_type,
  condition_status_code,
  evaluation_description,
  state_code,
  macroplot_acres,
  subplot_acres
FROM best_cond_per_group
ORDER BY subplot_acres DESC
LIMIT 10;