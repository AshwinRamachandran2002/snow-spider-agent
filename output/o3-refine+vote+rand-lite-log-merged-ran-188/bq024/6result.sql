-- Top-10 2012 evaluation groups based on the single condition that has the
-- largest subplot-level acres inside each group
WITH cond_pop AS (
  SELECT
    p.evaluation_group,
    p.evaluation_type,
    c.condition_status_code,
    p.evaluation_description,
    p.state_code,
    -- acreage estimates
    c.macroplot_proportion_unadjusted * p.expansion_factor AS macroplot_acres,
    c.subplot_proportion_unadjusted  * p.expansion_factor AS subplot_acres,
    -- rank conditions inside each evaluation group by their subplot acres
    ROW_NUMBER() OVER (
      PARTITION BY p.evaluation_group
      ORDER BY c.subplot_proportion_unadjusted * p.expansion_factor DESC
    ) AS rn
  FROM `bigquery-public-data.usfs_fia.condition`  AS c
  JOIN `bigquery-public-data.usfs_fia.population` AS p
    ON p.plot_sequence_number = c.plot_sequence_number
   AND p.inventory_year      = c.inventory_year
  WHERE c.inventory_year = 2012
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