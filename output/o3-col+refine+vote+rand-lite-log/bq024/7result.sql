-- Top-10 evaluation groups (2012) ranked by the single condition
-- that has the greatest subtotal of subplot acres (subplot_proportion × expansion_factor)
WITH cond_pop AS (
  SELECT
    pop.evaluation_group,
    pop.evaluation_type,
    cond.condition_status_code,
    pop.evaluation_description,
    pop.state_code,
    -- acreage estimates
    cond.macroplot_proportion_unadjusted * pop.expansion_factor AS macroplot_acres,
    cond.subplot_proportion_unadjusted  * pop.expansion_factor AS subplot_acres,
    -- pick the largest-acre condition within each evaluation group
    ROW_NUMBER() OVER (
      PARTITION BY pop.evaluation_group
      ORDER BY cond.subplot_proportion_unadjusted * pop.expansion_factor DESC
    ) AS rn
  FROM `bigquery-public-data.usfs_fia.population`  AS pop
  JOIN `bigquery-public-data.usfs_fia.condition`   AS cond
    ON pop.plot_sequence_number = cond.plot_sequence_number
  WHERE cond.inventory_year = 2012
)

SELECT
  evaluation_group,
  evaluation_type,
  condition_status_code,
  evaluation_description,
  state_code,
  macroplot_acres,
  subplot_acres
FROM cond_pop
WHERE rn = 1
ORDER BY subplot_acres DESC
LIMIT 10;