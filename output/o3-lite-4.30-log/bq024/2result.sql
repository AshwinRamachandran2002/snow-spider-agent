WITH best_condition AS (
  SELECT
    p.evaluation_group,
    p.evaluation_sequence_number,
    c.condition_status_code,
    c.subplot_proportion_unadjusted * p.expansion_factor                                    AS subplot_acres,
    COALESCE(c.macroplot_proportion_unadjusted,
             c.subplot_proportion_unadjusted) * p.expansion_factor                          AS macroplot_acres,
    ROW_NUMBER() OVER (
      PARTITION BY p.evaluation_group
      ORDER BY c.subplot_proportion_unadjusted * p.expansion_factor DESC
    ) AS rn
  FROM `bigquery-public-data.usfs_fia.population` AS p
  JOIN `bigquery-public-data.usfs_fia.condition`   AS c
    ON p.plot_sequence_number = c.plot_sequence_number
  WHERE p.report_year_name LIKE '%2012%'                 -- evaluations that include 2012
    AND c.subplot_proportion_unadjusted IS NOT NULL
    AND p.expansion_factor IS NOT NULL
),
evaluation_type_one AS (
  SELECT
    evaluation_sequence_number,
    MIN(evaluation_type) AS evaluation_type              -- choose a single type per evaluation
  FROM `bigquery-public-data.usfs_fia.population_evaluation_type`
  GROUP BY evaluation_sequence_number
)
SELECT
  eg.evaluation_group,
  et.evaluation_type,
  bc.condition_status_code,
  ev.evaluation_description,
  ev.state_code,
  ROUND(bc.macroplot_acres,4) AS macroplot_acres,
  ROUND(bc.subplot_acres,4)   AS subplot_acres
FROM best_condition bc
JOIN `bigquery-public-data.usfs_fia.population_evaluation`        AS ev
  ON bc.evaluation_sequence_number = ev.evaluation_sequence_number
JOIN `bigquery-public-data.usfs_fia.population_evaluation_group`  AS eg
  ON ev.evaluation_group_sequence_number = eg.evaluation_group_sequence_number
JOIN evaluation_type_one et
  ON et.evaluation_sequence_number = bc.evaluation_sequence_number
WHERE bc.rn = 1                                    -- keep the largest subplot acres condition per group
ORDER BY bc.subplot_acres DESC, eg.evaluation_group
LIMIT 10;