-- Top‐10  evaluation groups for report year 2012 by the single condition
-- that has the greatest subplot acres within each group
WITH condition_expansion AS (
  SELECT
    pop.evaluation_group,                         -- evaluation group id
    pop.evaluation_type,                          -- evaluation type (EXPCURR, EXPVOL …)
    pop.evaluation_description,                   -- description of the evaluation
    pop.state_code,                               -- state
    cond.condition_status_code,                   -- condition status
    -- subplot acres for this condition within this evaluation group
    IFNULL(cond.subplot_proportion_unadjusted,0)
      * IFNULL(pop.adjustment_factor_for_the_subplot,1)
      * pop.expansion_factor                                             AS subplot_acres,
    -- corresponding macro‑plot acres (for reference)
    IFNULL(cond.macroplot_proportion_unadjusted,0)
      * IFNULL(pop.adjustment_factor_for_the_macroplot,1)
      * pop.expansion_factor                                             AS macroplot_acres
  FROM `bigquery-public-data.usfs_fia.population` AS pop
  JOIN `bigquery-public-data.usfs_fia.condition`  AS cond
    ON pop.plot_sequence_number = cond.plot_sequence_number
   AND pop.inventory_year      = cond.inventory_year
   AND pop.state_code          = cond.state_code
  -- keep only evaluation groups that pertain to the year 2012
  WHERE REGEXP_CONTAINS(pop.evaluation_group_description, r'\b2012\b')
)
, ranked AS (
  SELECT *,
         ROW_NUMBER() OVER (PARTITION BY evaluation_group
                            ORDER BY subplot_acres DESC) AS rn
  FROM condition_expansion
)
SELECT
  evaluation_group,
  evaluation_type,
  condition_status_code,
  evaluation_description,
  state_code,
  macroplot_acres,
  subplot_acres
FROM ranked
WHERE rn = 1                      -- pick the single largest‑subplot condition per group
ORDER BY subplot_acres DESC       -- top 10 groups by those subplot acres
LIMIT 10;