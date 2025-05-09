-- Top-10 evaluation groups (report-year 2012) ranked by the
-- largest single-condition subplot acres inside each group
WITH joined AS (
  SELECT
    p.evaluation_group,
    p.evaluation_type,
    p.evaluation_description,
    p.state_code,
    c.condition_status_code,

    -- acreage calculations
    COALESCE(s.expansion_factor,0)
      * COALESCE(s.adjustment_factor_for_the_macroplot,1)
      * COALESCE(c.macroplot_proportion_unadjusted,0)          AS macroplot_acres,

    COALESCE(s.expansion_factor,0)
      * COALESCE(s.adjustment_factor_for_the_subplot,1)
      * COALESCE(c.subplot_proportion_unadjusted,0)            AS subplot_acres,

    -- rank conditions within each evaluation group
    ROW_NUMBER() OVER (PARTITION BY p.evaluation_group
                       ORDER BY
                         COALESCE(s.expansion_factor,0)
                         * COALESCE(s.adjustment_factor_for_the_subplot,1)
                         * COALESCE(c.subplot_proportion_unadjusted,0) DESC
                      ) AS rn
  FROM `bigquery-public-data.usfs_fia.population`         AS p
  JOIN `bigquery-public-data.usfs_fia.condition`          AS c
       ON c.plot_sequence_number = p.plot_sequence_number
  JOIN `bigquery-public-data.usfs_fia.population_stratum` AS s
       ON s.stratum_sequence_number = p.stratum_sequence_number
  -- keep only evaluation-groups whose report-year suffix is 2012
  WHERE MOD(p.evaluation_group, 10000) = 2012
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
WHERE rn = 1                    -- retain the largest-subplot condition per group
ORDER BY subplot_acres DESC
LIMIT 10;