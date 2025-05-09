/*------------------------------------------------------------*
 |  State with greatest timber‑ and forest‑land acreage        |
 |  (latest EXPCURR evaluation group for every state)          |
 *------------------------------------------------------------*/
WITH
-- 1.  Evaluation groups that have expansion factors (“EXPCURR”)
expg AS (
  SELECT
    eg.state_code,
    eg.evaluation_group,
    eg.evaluation_group_sequence_number
  FROM `bigquery-public-data.usfs_fia.population_evaluation_group`  AS eg
  JOIN `bigquery-public-data.usfs_fia.population_evaluation_type`   AS et
    ON et.evaluation_group_sequence_number = eg.evaluation_group_sequence_number
  WHERE et.evaluation_type = 'EXPCURR'
),

-- 2.  Latest evaluation group (largest code) for each state
latest AS (
  SELECT
    state_code,
    ARRAY_AGG(evaluation_group ORDER BY evaluation_group DESC LIMIT 1)[OFFSET(0)]
        AS evaluation_group,
    ARRAY_AGG(evaluation_group_sequence_number
              ORDER BY evaluation_group DESC LIMIT 1)[OFFSET(0)]
        AS evaluation_group_sequence_number
  FROM expg
  GROUP BY state_code
),

-- 3.  Population‑table rows that belong to the latest group
pop_factors AS (
  SELECT
    p.plot_sequence_number,
    p.state_code,
    p.adjustment_factor_for_the_macroplot AS fac_macr,
    p.adjustment_factor_for_the_subplot   AS fac_subp,
    l.evaluation_group
  FROM `bigquery-public-data.usfs_fia.population` AS p
  JOIN latest AS l
    ON  l.state_code                       = p.state_code
    AND l.evaluation_group_sequence_number = p.evaluation_group_sequence_number
),

-- 4.  Join conditions to those plots; keep only macro‑ & sub‑plot records
cond AS (
  SELECT
    pf.state_code,
    pf.evaluation_group,
    c.condition_status_code,
    c.reserved_status_code,
    c.site_productivity_class_code,
    c.proportion_basis,
    c.condition_proportion_unadjusted,
    pf.fac_macr,
    pf.fac_subp
  FROM pop_factors AS pf
  JOIN `bigquery-public-data.usfs_fia.condition` AS c
    ON c.plot_sequence_number = pf.plot_sequence_number
  WHERE c.proportion_basis IN ('MACR','SUBP')
),

-- 5.  Acres per state for both land classes
acres AS (
  SELECT
    state_code,
    evaluation_group,
    -- forest land (all condition_status_code = 1)
    SUM(
      CASE
        WHEN condition_status_code = 1 AND proportion_basis = 'MACR' AND fac_macr > 0
          THEN condition_proportion_unadjusted * fac_macr
        WHEN condition_status_code = 1 AND proportion_basis = 'SUBP' AND fac_subp > 0
          THEN condition_proportion_unadjusted * fac_subp
      END
    ) AS forest_acres,
    -- timber land (subset of forest land)
    SUM(
      CASE
        WHEN condition_status_code = 1
         AND reserved_status_code = 0
         AND site_productivity_class_code BETWEEN 1 AND 6
         AND proportion_basis = 'MACR' AND fac_macr > 0
          THEN condition_proportion_unadjusted * fac_macr
        WHEN condition_status_code = 1
         AND reserved_status_code = 0
         AND site_productivity_class_code BETWEEN 1 AND 6
         AND proportion_basis = 'SUBP' AND fac_subp > 0
          THEN condition_proportion_unadjusted * fac_subp
      END
    ) AS timber_acres
  FROM cond
  GROUP BY state_code, evaluation_group
),

-- 6.  Pick the single state with the greatest total for each category
top_forest AS (
  SELECT * FROM acres ORDER BY forest_acres DESC LIMIT 1
),
top_timber AS (
  SELECT * FROM acres ORDER BY timber_acres DESC LIMIT 1
),

-- 7.  Translate state‑code to state‑name (from the plot table)
state_names AS (
  SELECT DISTINCT plot_state_code AS state_code,
         plot_state_code_name     AS state_name
  FROM `bigquery-public-data.usfs_fia.plot`
)

-- 8.  Final two‑row result set
SELECT 'forestland'  AS category,
       f.state_code  AS state_cd,
       f.evaluation_group AS evalidgrp,
       sn.state_name,
       ROUND(f.forest_acres ,4) AS total_acres
FROM top_forest AS f
LEFT JOIN state_names AS sn USING (state_code)

UNION ALL

SELECT 'timberland'  AS category,
       t.state_code  AS state_cd,
       t.evaluation_group AS evalidgrp,
       sn.state_name,
       ROUND(t.timber_acres,4) AS total_acres
FROM top_timber AS t
LEFT JOIN state_names AS sn USING (state_code);