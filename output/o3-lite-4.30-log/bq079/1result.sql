WITH ex_curr_groups AS (   -- all evaluation‑groups of type EXPCURR
  SELECT
    eg.state_code,
    eg.region_or_station_code,
    eg.evaluation_group,                      -- numeric value (e.g., 482020)
    eg.pop_evaluation_group_created_date
  FROM `bigquery-public-data.usfs_fia.population_evaluation_group` AS eg
  JOIN `bigquery-public-data.usfs_fia.population_evaluation_type`  AS et
    ON et.evaluation_group_sequence_number = eg.evaluation_group_sequence_number
   AND et.evaluation_type = 'EXPCURR'
),
latest_per_state AS (       -- keep only the latest EXPCURR group for each state
  SELECT
    ARRAY_AGG(ecg ORDER BY ecg.pop_evaluation_group_created_date DESC)[OFFSET(0)] AS rec
  FROM ex_curr_groups ecg
  GROUP BY ecg.state_code
),
state_grp AS (              -- flatten the struct produced above
  SELECT
    rec.state_code,
    rec.region_or_station_code,
    rec.evaluation_group
  FROM latest_per_state
),
cond_base AS (              -- condition records with adjusted expansion factors
  SELECT
    sg.state_code,
    sg.evaluation_group,
    CASE
      WHEN c.proportion_basis = 'MACR'
           AND ps.adjustment_factor_for_the_macroplot > 0
           THEN ps.expansion_factor * ps.adjustment_factor_for_the_macroplot
      WHEN c.proportion_basis = 'SUBP'
           AND ps.adjustment_factor_for_the_subplot  > 0
           THEN ps.expansion_factor * ps.adjustment_factor_for_the_subplot
      ELSE ps.expansion_factor
    END AS adj_acres,
    -- timberland flag
    CASE
      WHEN c.condition_status_code = 1
       AND c.reserved_status_code  = 0
       AND c.site_productivity_class_code BETWEEN 1 AND 6
      THEN 1 ELSE 0 END AS is_timber,
    -- forestland flag
    CASE WHEN c.condition_status_code = 1 THEN 1 ELSE 0 END AS is_forest
  FROM state_grp sg
  JOIN `bigquery-public-data.usfs_fia.population_stratum_assign` AS sa
    ON sa.region_or_station_code = sg.region_or_station_code
   AND sa.evaluation_identifier  = sg.evaluation_group        -- crucial link
  JOIN `bigquery-public-data.usfs_fia.population_stratum`        AS ps
    ON ps.stratum_sequence_number = sa.stratum_sequence_number
  JOIN `bigquery-public-data.usfs_fia.condition`                 AS c
    ON c.plot_sequence_number = sa.plot_sequence_number
),
state_acres AS (            -- sum acres per state / evaluation group
  SELECT
    state_code,
    evaluation_group,
    SUM(CASE WHEN is_timber = 1 THEN adj_acres ELSE 0 END) AS timberland_acres,
    SUM(CASE WHEN is_forest = 1 THEN adj_acres ELSE 0 END) AS forestland_acres
  FROM cond_base
  GROUP BY state_code, evaluation_group
),
max_timber AS (             -- state w/ max timberland acres
  SELECT *
  FROM state_acres
  ORDER BY timberland_acres DESC
  LIMIT 1
),
max_forest AS (             -- state w/ max forestland acres
  SELECT *
  FROM state_acres
  ORDER BY forestland_acres DESC
  LIMIT 1
),
state_names AS (            -- lookup table for state names
  SELECT DISTINCT
    plot_state_code       AS state_code,
    plot_state_code_name  AS state_name
  FROM `bigquery-public-data.usfs_fia.plot`
)
SELECT
  'TIMBERLAND'                            AS category,
  mt.state_code                           AS state_cd,
  mt.evaluation_group                     AS evalidgrp,
  sn.state_name,
  ROUND(mt.timberland_acres, 4)           AS total_acres
FROM max_timber mt
LEFT JOIN state_names sn
  ON sn.state_code = mt.state_code

UNION ALL

SELECT
  'FORESTLAND'                            AS category,
  mf.state_code                           AS state_cd,
  mf.evaluation_group                     AS evalidgrp,
  sn.state_name,
  ROUND(mf.forestland_acres, 4)           AS total_acres
FROM max_forest mf
LEFT JOIN state_names sn
  ON sn.state_code = mf.state_code;