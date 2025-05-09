/* --- Highest‑acreage states, latest “EXPCURR” evaluation for each state --- */
WITH latest_eval_per_state AS (       -- most‑recent evaluation (EXPCURR) in every state
  SELECT
    e.state_code,
    e.evaluation_sequence_number,
    e.evaluation_group_sequence_number,
    ROW_NUMBER() OVER (
        PARTITION BY e.state_code
        ORDER BY SAFE_CAST(e.end_inventory_year AS INT64) DESC,
                 e.evaluation_sequence_number DESC) AS rn
  FROM `bigquery-public-data.usfs_fia.population_evaluation_type`   et
  JOIN `bigquery-public-data.usfs_fia.population_evaluation`        e
    ON et.evaluation_sequence_number = e.evaluation_sequence_number
  WHERE et.evaluation_type = 'EXPCURR'
),
selected_eval AS (                   -- keep only the latest evaluation per state
  SELECT state_code,
         evaluation_sequence_number
  FROM   latest_eval_per_state
  WHERE  rn = 1
),
base AS (                            -- condition–level adjusted expansion factor
  SELECT
    p.state_code,
    c.state_code_name                         AS state_name,
    p.evaluation_group,
    CASE                                         -- adjusted expansion factor (acres)
      WHEN c.proportion_basis = 'MACR' THEN
        p.expansion_factor * c.macroplot_proportion_unadjusted *
        (CASE WHEN p.adjustment_factor_for_the_macroplot > 0
              THEN p.adjustment_factor_for_the_macroplot ELSE 1 END)
      WHEN c.proportion_basis = 'SUBP' THEN
        p.expansion_factor * c.subplot_proportion_unadjusted *
        (CASE WHEN p.adjustment_factor_for_the_subplot  > 0
              THEN p.adjustment_factor_for_the_subplot  ELSE 1 END)
      ELSE 0
    END                                          AS adj_acres,
    c.condition_status_code,
    c.reserved_status_code,
    c.site_productivity_class_code
  FROM `bigquery-public-data.usfs_fia.population`  p
  JOIN selected_eval  se
    ON p.evaluation_sequence_number = se.evaluation_sequence_number
  JOIN `bigquery-public-data.usfs_fia.condition`   c
    ON p.plot_sequence_number = c.plot_sequence_number
   AND p.inventory_year     = c.inventory_year
),
aggregated AS (                      -- acres per state (latest evaluation only)
  SELECT
    state_code,
    state_name,
    evaluation_group,
    SUM(CASE WHEN condition_status_code = 1
             THEN adj_acres ELSE 0 END)                                   AS forestland_acres,
    SUM(CASE WHEN condition_status_code = 1
              AND reserved_status_code = 0
              AND site_productivity_class_code BETWEEN 1 AND 6
             THEN adj_acres ELSE 0 END)                                   AS timberland_acres
  FROM base
  GROUP BY state_code, state_name, evaluation_group
),
top_timber AS (                      -- state with greatest timberland acres
  SELECT 'TIMBERLAND'                AS category,
         state_code,
         evaluation_group,
         state_name,
         timberland_acres            AS total_acres
  FROM   aggregated
  ORDER BY timberland_acres DESC
  LIMIT 1
),
top_forest AS (                      -- state with greatest forestland acres
  SELECT 'FORESTLAND'                AS category,
         state_code,
         evaluation_group,
         state_name,
         forestland_acres            AS total_acres
  FROM   aggregated
  ORDER BY forestland_acres DESC
  LIMIT 1
)
SELECT * FROM top_timber
UNION ALL
SELECT * FROM top_forest;