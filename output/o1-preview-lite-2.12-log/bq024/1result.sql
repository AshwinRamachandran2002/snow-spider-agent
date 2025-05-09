SELECT
  evaluation_group,
  evaluation_type,
  condition_status_code,
  evaluation_description,
  state_code,
  macroplot_acres,
  subplot_acres
FROM (
  SELECT
    p.evaluation_group,
    p.evaluation_type,
    c.condition_status_code,
    p.evaluation_description,
    p.state_code,
    (p.expansion_factor * c.condition_proportion_unadjusted * COALESCE(NULLIF(p.adjustment_factor_for_the_macroplot, 0), 1)) AS macroplot_acres,
    (p.expansion_factor * c.condition_proportion_unadjusted * COALESCE(NULLIF(p.adjustment_factor_for_the_subplot, 0), 1)) AS subplot_acres,
    ROW_NUMBER() OVER (
      PARTITION BY p.evaluation_group
      ORDER BY (p.expansion_factor * c.condition_proportion_unadjusted * COALESCE(NULLIF(p.adjustment_factor_for_the_subplot, 0), 1)) DESC
    ) AS rn
  FROM `bigquery-public-data.usfs_fia.condition` AS c
  INNER JOIN `bigquery-public-data.usfs_fia.population` AS p
    ON c.plot_sequence_number = p.plot_sequence_number
  WHERE
    SAFE_CAST(p.start_inventory_year AS INT64) <= 2012
    AND SAFE_CAST(p.end_inventory_year AS INT64) >= 2012
    AND p.expansion_factor IS NOT NULL
    AND c.condition_proportion_unadjusted IS NOT NULL
    AND p.expansion_factor > 0
    AND c.condition_proportion_unadjusted > 0
)
WHERE rn = 1
ORDER BY subplot_acres DESC
LIMIT 10;