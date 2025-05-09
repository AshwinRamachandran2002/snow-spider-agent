WITH best_condition_per_group AS (
  SELECT
    p.evaluation_group,
    p.evaluation_type,
    c.condition_status_code,
    p.evaluation_description,
    p.state_code,
    c.macroplot_proportion_unadjusted AS macroplot_acres,
    c.subplot_proportion_unadjusted   AS subplot_acres,
    ROW_NUMBER() OVER (
        PARTITION BY p.evaluation_group
        ORDER BY c.subplot_proportion_unadjusted DESC NULLS LAST
    ) AS rn
  FROM `bigquery-public-data.usfs_fia.population` AS p
  JOIN `bigquery-public-data.usfs_fia.condition`  AS c
    ON c.plot_sequence_number = p.plot_sequence_number
   AND c.inventory_year       = 2012
  WHERE p.evaluation_description LIKE '%2012%'
)

SELECT
  evaluation_group,
  evaluation_type,
  condition_status_code,
  evaluation_description,
  state_code,
  macroplot_acres,
  subplot_acres
FROM best_condition_per_group
WHERE rn = 1
ORDER BY subplot_acres DESC
LIMIT 10;