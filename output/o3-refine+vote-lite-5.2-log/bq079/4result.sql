/* -----------------------------------------------------------
   State with greatest timber‑ and forest‑land acreage
   (latest EXPCURR evaluation per state)
-------------------------------------------------------------*/
WITH latest_eval AS (   -- most recent EXPCURR evaluation year for every state
  SELECT
    ev.state_code,
    MAX(CAST(ev.end_inventory_year AS INT64)) AS max_year
  FROM `bigquery-public-data.usfs_fia.population_evaluation` ev
  JOIN `bigquery-public-data.usfs_fia.population_evaluation_type` evt
    ON evt.evaluation_sequence_number = ev.evaluation_sequence_number
   AND evt.evaluation_type = 'EXPCURR'
  GROUP BY ev.state_code
),
latest_eval_seq AS (    -- evaluation_sequence_numbers of those latest evals
  SELECT ev.evaluation_sequence_number
  FROM `bigquery-public-data.usfs_fia.population_evaluation` ev
  JOIN latest_eval le
    ON  le.state_code = ev.state_code
   AND CAST(ev.end_inventory_year AS INT64) = le.max_year
  JOIN `bigquery-public-data.usfs_fia.population_evaluation_type` evt
    ON evt.evaluation_sequence_number = ev.evaluation_sequence_number
   AND evt.evaluation_type = 'EXPCURR'
),
pop_curr AS (           -- population rows for the latest EXPCURR evaluations
  SELECT *
  FROM `bigquery-public-data.usfs_fia.population`
  WHERE evaluation_sequence_number IN (SELECT evaluation_sequence_number
                                       FROM   latest_eval_seq)
    AND evaluation_type = 'EXPCURR'
),
joined AS (             -- attach CONDITION table, compute adjusted acres
  SELECT
    c.state_code,
    c.state_code_name                      AS state_name,
    p.evaluation_group,
    c.condition_status_code,
    c.reserved_status_code,
    c.site_productivity_class_code,
    CASE
      WHEN c.proportion_basis = 'MACR' THEN
           c.condition_proportion_unadjusted
           * p.expansion_factor
           * IF(p.adjustment_factor_for_the_macroplot  > 0,
                p.adjustment_factor_for_the_macroplot ,1)
      WHEN c.proportion_basis = 'SUBP' THEN
           c.condition_proportion_unadjusted
           * p.expansion_factor
           * IF(p.adjustment_factor_for_the_subplot    > 0,
                p.adjustment_factor_for_the_subplot   ,1)
      ELSE 0
    END                                     AS adj_acres
  FROM `bigquery-public-data.usfs_fia.condition` c
  JOIN pop_curr p
    ON p.plot_sequence_number = c.plot_sequence_number
),
forestland AS (         -- total forest‑land acres per state
  SELECT
    state_code,
    MAX(evaluation_group)      AS evaluation_group,
    MAX(state_name)            AS state_name,
    SUM(adj_acres)             AS total_acres
  FROM joined
  WHERE condition_status_code = 1
  GROUP BY state_code
),
timberland AS (         -- total timber‑land acres per state
  SELECT
    state_code,
    MAX(evaluation_group)      AS evaluation_group,
    MAX(state_name)            AS state_name,
    SUM(adj_acres)             AS total_acres
  FROM joined
  WHERE condition_status_code = 1
    AND reserved_status_code   = 0
    AND site_productivity_class_code BETWEEN 1 AND 6
  GROUP BY state_code
),
forestland_max AS (SELECT * FROM forestland ORDER BY total_acres DESC LIMIT 1),
timberland_max AS (SELECT * FROM timberland ORDER BY total_acres DESC LIMIT 1)

SELECT 'FORESTLAND' AS category,
       state_code,
       evaluation_group,
       state_name,
       total_acres
FROM forestland_max
UNION ALL
SELECT 'TIMBERLAND',
       state_code,
       evaluation_group,
       state_name,
       total_acres
FROM timberland_max;