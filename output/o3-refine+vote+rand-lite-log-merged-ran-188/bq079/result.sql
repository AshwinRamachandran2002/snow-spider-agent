/* State that has the greatest acreage of
      – TIMBERLAND  (cond_stat_cd =1 , reserve_cd =0 , site_prod_cd 1‑6)
      – FORESTLAND  (cond_stat_cd =1)
   using ONLY the most‑recent evaluation‑group per state whose evaluation‑type is
   ‘EXPCURR’.                                                             */

WITH latest_eval_per_state AS (      -- most recent EXPCURR evaluation‑group in each state
  SELECT
    pe.state_code,
    pe.evaluation_group_sequence_number,
    eg.evaluation_group,
    ROW_NUMBER() OVER (PARTITION BY pe.state_code
                       ORDER BY eg.evaluation_group DESC) AS rn
  FROM `bigquery-public-data.usfs_fia.population_evaluation_type` et
  JOIN `bigquery-public-data.usfs_fia.population_evaluation`      pe
       ON pe.evaluation_sequence_number = et.evaluation_sequence_number
  JOIN `bigquery-public-data.usfs_fia.population_evaluation_group` eg
       ON eg.evaluation_group_sequence_number = pe.evaluation_group_sequence_number
  WHERE et.evaluation_type = 'EXPCURR'
),
chosen_eval AS (                    -- keep only the newest for each state
  SELECT state_code,
         evaluation_group_sequence_number,
         evaluation_group
  FROM   latest_eval_per_state
  WHERE  rn = 1
),
-- rows from POPULATION that belong to the chosen (latest) EXPCURR group
pop AS (
  SELECT
      p.plot_sequence_number,
      p.expansion_factor,
      p.adjustment_factor_for_the_macroplot,
      p.adjustment_factor_for_the_subplot,
      ce.state_code,
      ce.evaluation_group
  FROM `bigquery-public-data.usfs_fia.population` p
  JOIN chosen_eval ce
    ON ce.evaluation_group_sequence_number = p.evaluation_group_sequence_number
  WHERE p.evaluation_type = 'EXPCURR'
),
-- attach condition information and compute adjusted acres
cond_acres AS (
  SELECT
    ce.state_code,
    ce.evaluation_group,
    c.state_code_name AS state_name,
    c.condition_status_code,
    c.reserved_status_code,
    c.site_productivity_class_code,
    -- adjust expansion factor for macroplot / subplot if adjustment > 0
    ce.expansion_factor *
    CASE
      WHEN c.proportion_basis = 'MACR'
           THEN IF(ce.adjustment_factor_for_the_macroplot > 0,
                   ce.adjustment_factor_for_the_macroplot, 1)
      WHEN c.proportion_basis = 'SUBP'
           THEN IF(ce.adjustment_factor_for_the_subplot   > 0,
                   ce.adjustment_factor_for_the_subplot,   1)
      ELSE 1
    END AS acres
  FROM pop              ce
  JOIN `bigquery-public-data.usfs_fia.condition` c
       ON c.plot_sequence_number = ce.plot_sequence_number
),
/* aggregate acres by state for the two land bases ----------------------*/
timberland_state AS (
  SELECT
    state_code,
    evaluation_group,
    ANY_VALUE(state_name) AS state_name,
    SUM(acres) AS total_acres
  FROM cond_acres
  WHERE condition_status_code = 1                 -- forest land
    AND reserved_status_code  = 0                 -- not reserved
    AND site_productivity_class_code BETWEEN 1 AND 6
  GROUP BY state_code, evaluation_group
),
forestland_state AS (
  SELECT
    state_code,
    evaluation_group,
    ANY_VALUE(state_name) AS state_name,
    SUM(acres) AS total_acres
  FROM cond_acres
  WHERE condition_status_code = 1
  GROUP BY state_code, evaluation_group
),
-- pick the single state with the greatest acres for each land base
timberland_top AS (
  SELECT *
  FROM timberland_state
  ORDER BY total_acres DESC
  LIMIT 1
),
forestland_top AS (
  SELECT *
  FROM forestland_state
  ORDER BY total_acres DESC
  LIMIT 1
)
-- final combined answer
SELECT 'TIMBERLAND' AS category,
       state_code,
       evaluation_group,
       state_name,
       total_acres
FROM timberland_top
UNION ALL
SELECT 'FORESTLAND',
       state_code,
       evaluation_group,
       state_name,
       total_acres
FROM forestland_top;