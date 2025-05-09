WITH subquery AS (
  SELECT
    p.evaluation_group,
    p.evaluation_type,
    c.condition_status_code,
    pe.evaluation_description,
    p.state_code,
    p.plot_sequence_number,
    c.condition_class_number,
    p.expansion_factor,
    c.condition_proportion_unadjusted,
    -- Use adjustment factors, defaulting to 1 if NULL or zero
    COALESCE(NULLIF(p.adjustment_factor_for_the_subplot, 0), 1) AS adjustment_factor_for_the_subplot,
    COALESCE(NULLIF(p.adjustment_factor_for_the_macroplot, 0), 1) AS adjustment_factor_for_the_macroplot,
    -- Calculate subplot acres
    (p.expansion_factor * c.condition_proportion_unadjusted * 
      COALESCE(NULLIF(p.adjustment_factor_for_the_subplot, 0), 1)
    ) AS subplot_acres,
    -- Calculate macroplot acres
    (p.expansion_factor * c.condition_proportion_unadjusted * 
      COALESCE(NULLIF(p.adjustment_factor_for_the_macroplot, 0), 1)
    ) AS macroplot_acres
  FROM
    `bigquery-public-data.usfs_fia.population` AS p
  JOIN
    `bigquery-public-data.usfs_fia.condition` AS c
    ON p.plot_sequence_number = c.plot_sequence_number
  JOIN
    `bigquery-public-data.usfs_fia.population_evaluation` AS pe
    ON p.evaluation_sequence_number = pe.evaluation_sequence_number
  WHERE
    c.inventory_year = 2012
    AND (pe.start_inventory_year = '2012' OR pe.end_inventory_year = '2012')
    AND p.expansion_factor IS NOT NULL
    AND p.expansion_factor > 0
    AND c.condition_proportion_unadjusted IS NOT NULL
    AND c.condition_proportion_unadjusted > 0
)
SELECT
  evaluation_group,
  evaluation_type,
  condition_status_code,
  evaluation_description,
  state_code,
  ROUND(macroplot_acres, 4) AS macroplot_acres,
  ROUND(subplot_acres, 4) AS subplot_acres
FROM (
  SELECT
    evaluation_group,
    evaluation_type,
    condition_status_code,
    evaluation_description,
    state_code,
    macroplot_acres,
    subplot_acres,
    ROW_NUMBER() OVER (PARTITION BY evaluation_group ORDER BY subplot_acres DESC) AS rn
  FROM
    subquery
)
WHERE rn = 1
ORDER BY subplot_acres DESC
LIMIT 10