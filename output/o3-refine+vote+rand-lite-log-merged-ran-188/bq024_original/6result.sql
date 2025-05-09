-- Top 10 evaluation groups (report year 2012) ranked by the
-- largest subplot acres (subplot_proportion_unadjusted) observed
-- among their conditions.  We keep only the single condition with
-- the greatest subplot acres within each evaluation group.

WITH joined AS (
  SELECT
    p.evaluation_group,                -- evaluation group id
    p.evaluation_type,                 -- evaluation type (EXPCURR, EXPGROW, etc.)
    p.evaluation_description,          -- textual description of evaluation
    p.state_code,                      -- state involved in the evaluation
    c.condition_status_code,           -- condition status (e.g., 1 = accessible forest)
    c.macroplot_proportion_unadjusted  AS macroplot_acres,   -- macro‑plot acres (proportion)
    c.subplot_proportion_unadjusted    AS subplot_acres      -- sub‑plot acres (proportion)
  FROM `bigquery-public-data.usfs_fia.population` AS p
  JOIN `bigquery-public-data.usfs_fia.condition`  AS c
    ON p.plot_sequence_number = c.plot_sequence_number
   AND p.inventory_year      = c.inventory_year
  WHERE c.inventory_year = 2012              -- focus on 2012
    AND c.subplot_proportion_unadjusted IS NOT NULL
),

-- keep only the single condition per evaluation group with the
-- largest subplot acres
best_per_group AS (
  SELECT *
  FROM (
    SELECT
      j.*,
      ROW_NUMBER() OVER (
        PARTITION BY j.evaluation_group
        ORDER BY j.subplot_acres DESC, j.macroplot_acres DESC
      ) AS rn
    FROM joined AS j
  )
  WHERE rn = 1
)

SELECT
  evaluation_group,
  evaluation_type,
  condition_status_code,
  evaluation_description,
  state_code,
  macroplot_acres,
  subplot_acres
FROM best_per_group
ORDER BY subplot_acres DESC
LIMIT 10;