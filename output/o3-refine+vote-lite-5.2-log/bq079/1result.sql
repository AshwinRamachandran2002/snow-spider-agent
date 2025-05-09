/*  ------------------------------------------------------------
    Timberland & Forestland acreage leaders
    ------------------------------------------------------------
    •  Latest evaluation group per state  ->  population_evaluation_group
    •  Keep only evaluation type ‘EXPCURR’ ->  population_evaluation_type / population
    •  Area   =  expansion_factor
                 × chosen adjustment_factor   (MACR ↔ adjustment_factor_for_the_macroplot,
                                               SUBP ↔ adjustment_factor_for_the_subplot,
                                               use 1 when the factor is NULL or ≤ 0)
                 × proportional area          (MACR ↔ macroplot_proportion_unadjusted,
                                               SUBP ↔ subplot_proportion_unadjusted;
                                               fall‐back to condition_proportion_unadjusted)
    •  Timberland filters  :  condition_status_code = 1
                              reserved_status_code  = 0
                              site_productivity_class_code BETWEEN 1 AND 6
       Forestland filters  :  condition_status_code = 1
----------------------------------------------------------------- */
WITH latest_eval_per_state AS (            -- most‐recent evaluation group for each state
  SELECT
    state_code,
    MAX(evaluation_group) AS latest_evaluation_group
  FROM `bigquery-public-data.usfs_fia.population_evaluation_group`
  GROUP BY state_code
),
chosen_eval AS (                          -- rows for those latest groups
  SELECT peg.evaluation_group_sequence_number,
         peg.state_code,
         peg.evaluation_group
  FROM `bigquery-public-data.usfs_fia.population_evaluation_group` peg
  JOIN latest_eval_per_state l
    ON  l.state_code             = peg.state_code
   AND l.latest_evaluation_group = peg.evaluation_group
),
pop_expcurr AS (                           -- population records for EXPCURR in the latest group
  SELECT
    p.plot_sequence_number,
    p.state_code,
    p.evaluation_group,
    MAX(p.expansion_factor)                      AS expansion_factor,
    MAX(p.adjustment_factor_for_the_macroplot)   AS adj_macr,
    MAX(p.adjustment_factor_for_the_subplot)     AS adj_subp
  FROM `bigquery-public-data.usfs_fia.population` p
  JOIN chosen_eval ce
    ON ce.state_code       = p.state_code
   AND ce.evaluation_group = p.evaluation_group
  WHERE p.evaluation_type = 'EXPCURR'
  GROUP BY plot_sequence_number, state_code, evaluation_group
),
cond_x_pop AS (                             -- join conditions to population info
  SELECT
    c.state_code,
    c.state_code_name                     AS state_name,
    c.proportion_basis,
    c.macroplot_proportion_unadjusted,
    c.subplot_proportion_unadjusted,
    c.condition_proportion_unadjusted,
    c.condition_status_code,
    c.reserved_status_code,
    c.site_productivity_class_code,
    p.evaluation_group,
    p.expansion_factor,
    p.adj_macr,
    p.adj_subp
  FROM `bigquery-public-data.usfs_fia.condition` c
  JOIN pop_expcurr p
    ON  p.plot_sequence_number = c.plot_sequence_number
),
calc_area AS (                              -- compute acres per condition
  SELECT
    state_code,
    state_name,
    evaluation_group,
    CASE
      WHEN proportion_basis = 'MACR' THEN
           expansion_factor
           * IFNULL(NULLIF(adj_macr,0),1)
           * COALESCE(macroplot_proportion_unadjusted , condition_proportion_unadjusted ,0)
      WHEN proportion_basis = 'SUBP' THEN
           expansion_factor
           * IFNULL(NULLIF(adj_subp,0),1)
           * COALESCE(subplot_proportion_unadjusted   , condition_proportion_unadjusted ,0)
      ELSE 0
    END AS acres,
    condition_status_code,
    reserved_status_code,
    site_productivity_class_code
  FROM cond_x_pop
),
timberland_by_state AS (
  SELECT
    state_code,
    MAX(state_name)            AS state_name,
    evaluation_group,
    SUM(acres)                 AS total_acres
  FROM calc_area
  WHERE condition_status_code = 1
    AND reserved_status_code  = 0
    AND site_productivity_class_code BETWEEN 1 AND 6
  GROUP BY state_code, evaluation_group
),
forestland_by_state AS (
  SELECT
    state_code,
    MAX(state_name)            AS state_name,
    evaluation_group,
    SUM(acres)                 AS total_acres
  FROM calc_area
  WHERE condition_status_code = 1
  GROUP BY state_code, evaluation_group
),
max_timber AS (                            -- state with largest timberland acreage
  SELECT *
  FROM timberland_by_state
  QUALIFY total_acres = MAX(total_acres) OVER ()
),
max_forest AS (                            -- state with largest forestland acreage
  SELECT *
  FROM forestland_by_state
  QUALIFY total_acres = MAX(total_acres) OVER ()
)
SELECT 'TIMBERLAND' AS category,
       state_code,
       evaluation_group,
       state_name,
       total_acres
FROM max_timber
UNION ALL
SELECT 'FORESTLAND',
       state_code,
       evaluation_group,
       state_name,
       total_acres
FROM max_forest
ORDER BY category;