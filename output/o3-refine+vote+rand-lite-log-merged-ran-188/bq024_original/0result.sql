WITH cond_area AS (
  SELECT
    p.evaluation_group,
    p.evaluation_type,
    c.condition_status_code,
    p.evaluation_description,
    p.state_code,
    -- acres represented by the condition on the macro‑ and sub‑plot scale
    COALESCE(p.expansion_factor,0) * COALESCE(c.macroplot_proportion_unadjusted,0)  AS macroplot_acres,
    COALESCE(p.expansion_factor,0) * COALESCE(c.subplot_proportion_unadjusted,0)     AS subplot_acres
  FROM  `bigquery-public-data.usfs_fia.population`  AS p
  JOIN  `bigquery-public-data.usfs_fia.condition`   AS c
    ON  p.plot_sequence_number     = c.plot_sequence_number
    AND p.inventory_year           = c.inventory_year
    AND p.state_code               = c.state_code
    AND p.survey_unit_code         = c.survey_unit_code
    AND p.county_code              = c.county_code
    AND p.phase_2_plot_number      = c.phase_2_plot_number
  -- keep evaluation groups for the year 2012
  WHERE MOD(p.evaluation_group, 10000) = 2012
),

best_cond_per_group AS (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY evaluation_group ORDER BY subplot_acres DESC) AS rn
  FROM cond_area
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
WHERE rn = 1               -- only the condition with the largest subplot acres per group
ORDER BY subplot_acres DESC
LIMIT 10;