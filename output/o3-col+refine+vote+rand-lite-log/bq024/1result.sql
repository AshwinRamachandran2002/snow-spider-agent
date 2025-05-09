WITH joined AS (
  SELECT
    p.evaluation_group,
    p.evaluation_type,
    c.condition_status_code,
    p.evaluation_description,
    p.state_code,
    (p.expansion_factor * p.adjustment_factor_for_the_macroplot *
     c.macroplot_proportion_unadjusted) AS macroplot_acres,
    (p.expansion_factor * p.adjustment_factor_for_the_subplot *
     c.subplot_proportion_unadjusted)   AS subplot_acres,
    ROW_NUMBER() OVER (
        PARTITION BY p.evaluation_group
        ORDER BY (p.expansion_factor * p.adjustment_factor_for_the_subplot *
                  c.subplot_proportion_unadjusted) DESC
    ) AS rn
  FROM `bigquery-public-data.usfs_fia.population`  AS p
  JOIN `bigquery-public-data.usfs_fia.condition`   AS c
    ON  p.plot_sequence_number = c.plot_sequence_number
    AND p.inventory_year       = c.inventory_year
  WHERE p.inventory_year = 2012
)

SELECT
  evaluation_group,
  evaluation_type,
  condition_status_code,
  evaluation_description,
  state_code,
  macroplot_acres,
  subplot_acres
FROM joined
WHERE rn = 1                -- keep only the largest-subplot condition in each group
ORDER BY subplot_acres DESC -- top 10 groups by subplot acres
LIMIT 10;