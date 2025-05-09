WITH per_condition AS (
  SELECT
    pop.evaluation_group,
    pop.evaluation_type,
    cond.condition_status_code,
    pop.evaluation_description,
    pop.state_code,
    ROUND(COALESCE(cond.macroplot_proportion_unadjusted,0) * pop.expansion_factor,4) AS macroplot_acres,
    ROUND(cond.subplot_proportion_unadjusted * pop.expansion_factor,4)               AS subplot_acres,
    ROW_NUMBER() OVER (
        PARTITION BY pop.evaluation_group
        ORDER BY cond.subplot_proportion_unadjusted * pop.expansion_factor DESC
    ) AS rn
  FROM `bigquery-public-data.usfs_fia.population` AS pop
  JOIN `bigquery-public-data.usfs_fia.condition`  AS cond
    ON  pop.plot_sequence_number = cond.plot_sequence_number
    AND pop.inventory_year       = cond.inventory_year
  -- keep only evaluation groups for the year 2012
  WHERE MOD(pop.evaluation_group, 10000) = 2012
)

SELECT
  CAST(evaluation_group AS STRING) AS evaluation_group,
  evaluation_type,
  condition_status_code,
  evaluation_description,
  state_code,
  macroplot_acres,
  subplot_acres
FROM per_condition
WHERE rn = 1              -- largest‑subplot condition per group
ORDER BY subplot_acres DESC
LIMIT 10;