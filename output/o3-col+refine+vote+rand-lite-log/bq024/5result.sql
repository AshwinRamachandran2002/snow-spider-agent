-- Top-10  “2012” evaluation groups ranked by the single condition
-- that gives the largest subplot acres inside each group.
WITH joined AS (
  SELECT
    eg.evaluation_group,
    p.evaluation_type,
    c.condition_status_code,
    e.evaluation_description,
    p.state_code,
    -- convert plot-level proportions to acres
    IFNULL(c.subplot_proportion_unadjusted,0) * IFNULL(p.expansion_factor,0) AS subplot_acres,
    IFNULL(c.macroplot_proportion_unadjusted,0) * IFNULL(p.expansion_factor,0) AS macroplot_acres
  FROM `bigquery-public-data.usfs_fia.population`            AS p
  JOIN `bigquery-public-data.usfs_fia.condition`             AS c
        ON p.plot_sequence_number = c.plot_sequence_number
  JOIN `bigquery-public-data.usfs_fia.population_evaluation` AS e
        ON p.evaluation_sequence_number = e.evaluation_sequence_number
  JOIN `bigquery-public-data.usfs_fia.population_evaluation_group` AS eg
        ON e.evaluation_group_sequence_number = eg.evaluation_group_sequence_number
  -- keep only the 2012 evaluation groups
  WHERE eg.evaluation_group_description LIKE '% 2012:%'
),
ranked AS (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY evaluation_group
                       ORDER BY subplot_acres DESC) AS rn
  FROM joined
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
WHERE rn = 1
ORDER BY subplot_acres DESC
LIMIT 10;