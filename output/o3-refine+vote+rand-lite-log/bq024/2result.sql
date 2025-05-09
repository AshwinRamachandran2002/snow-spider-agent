-- Top‑10  evaluation groups (year 2012) by the single largest subplot‑acre condition
WITH joined AS (
  SELECT
      p.evaluation_group                      AS evaluation_group,
      p.evaluation_group_sequence_number      AS evaluation_group_sequence_number,
      p.evaluation_group_description,
      p.evaluation_type,
      p.evaluation_description,
      c.condition_status_code,
      c.state_code,
      -- acres calculated from FIA area‑expansion recipe
      ( IFNULL(c.macroplot_proportion_unadjusted,0)
        * IFNULL(p.expansion_factor,0)
        * IFNULL(p.adjustment_factor_for_the_macroplot,1)
      )                                       AS macroplot_acres,
      ( IFNULL(c.subplot_proportion_unadjusted,0)
        * IFNULL(p.expansion_factor,0)
        * IFNULL(p.adjustment_factor_for_the_subplot,1)
      )                                       AS subplot_acres
  FROM `bigquery-public-data.usfs_fia.population` p
  JOIN `bigquery-public-data.usfs_fia.condition`  c
    ON p.plot_sequence_number = c.plot_sequence_number
  -- keep only evaluation‑groups whose description indicates report year 2012
  WHERE ( p.evaluation_group_description LIKE '%2012%'
       OR p.evaluation_description       LIKE '%2012%' )
),

-- pick the single condition with the largest subplot acres inside each evaluation group
ranked AS (
  SELECT *,
         ROW_NUMBER() OVER (PARTITION BY evaluation_group_sequence_number
                            ORDER BY subplot_acres DESC) AS rn
  FROM joined
)

SELECT
    evaluation_group,
    evaluation_type,
    condition_status_code,
    evaluation_description,
    state_code,
    ROUND(macroplot_acres,4)   AS macroplot_acres,
    ROUND(subplot_acres,4)     AS subplot_acres
FROM ranked
WHERE rn = 1                         -- largest subplot‑acre condition per group
ORDER BY subplot_acres DESC
LIMIT 10;