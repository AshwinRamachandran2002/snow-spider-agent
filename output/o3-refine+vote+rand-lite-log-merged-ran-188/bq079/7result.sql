/*  State with the largest acreage of
    1) timberland (condition_status_code = 1, reserved_status_code = 0, site_productivity_class_code 1‑6)
    2) forestland (condition_status_code = 1)

    – Only consider the most‑recent evaluation group for each state having
      evaluation_type = 'EXPCURR'.
    – Acres = expansion_factor × condition/subplot proportion ×
      appropriate adjustment‑factor (>0 → use, else 1).
*/

WITH latest_eval_per_state AS (          -- latest “EXPCURR” evaluation group for every state
  SELECT state_code,
         evaluation_group_sequence_number
  FROM (
    SELECT state_code,
           evaluation_group_sequence_number,
           MAX(CAST(end_inventory_year AS INT64))              AS end_yr,
           ROW_NUMBER() OVER (PARTITION BY state_code
                              ORDER BY MAX(CAST(end_inventory_year AS INT64)) DESC,
                                       evaluation_group_sequence_number DESC) AS rn
    FROM `bigquery-public-data.usfs_fia.population`
    WHERE evaluation_type = 'EXPCURR'
    GROUP BY state_code, evaluation_group_sequence_number
  )
  WHERE rn = 1
),

pop AS (                                 -- population rows restricted to those latest groups
  SELECT p.*
  FROM `bigquery-public-data.usfs_fia.population` AS p
  JOIN latest_eval_per_state AS le
    ON  le.state_code = p.state_code
    AND le.evaluation_group_sequence_number = p.evaluation_group_sequence_number
  WHERE p.evaluation_type = 'EXPCURR'
),

cond_join AS (                           -- join to condition table to get needed filters/props
  SELECT
    p.state_code,
    p.evaluation_group,
    p.location_name                       AS state_name,
    c.condition_status_code,
    c.reserved_status_code,
    c.site_productivity_class_code,
    c.proportion_basis,
    c.condition_proportion_unadjusted,
    c.subplot_proportion_unadjusted,
    p.expansion_factor,
    p.adjustment_factor_for_the_macroplot,
    p.adjustment_factor_for_the_subplot
  FROM pop AS p
  JOIN `bigquery-public-data.usfs_fia.condition` AS c
    ON  c.plot_sequence_number = p.plot_sequence_number
    AND c.inventory_year    = p.inventory_year
),

acres AS (                               -- compute adjusted acres for every qualifying row
  SELECT
    *,
    CASE
      WHEN proportion_basis = 'MACR' THEN
           COALESCE(condition_proportion_unadjusted,0) *
           COALESCE(expansion_factor,0) *
           COALESCE(NULLIF(adjustment_factor_for_the_macroplot,0),1)
      WHEN proportion_basis = 'SUBP' THEN
           COALESCE(subplot_proportion_unadjusted,0) *
           COALESCE(expansion_factor,0) *
           COALESCE(NULLIF(adjustment_factor_for_the_subplot,0),1)
      ELSE 0
    END AS adj_acres
  FROM cond_join
),

-- forestland = all condition_status_code = 1
forestland_state AS (
  SELECT state_code,
         evaluation_group,
         state_name,
         SUM(adj_acres) AS total_acres
  FROM acres
  WHERE condition_status_code = 1
  GROUP BY state_code, evaluation_group, state_name
),

-- timberland = forestland plus reserved_status_code = 0 and productivity 1‑6
timberland_state AS (
  SELECT state_code,
         evaluation_group,
         state_name,
         SUM(adj_acres) AS total_acres
  FROM acres
  WHERE condition_status_code = 1
    AND reserved_status_code   = 0
    AND site_productivity_class_code BETWEEN 1 AND 6
  GROUP BY state_code, evaluation_group, state_name
),

max_forestland AS (                      -- top state for forestland
  SELECT 'FORESTLAND'                   AS category,
         state_code,
         evaluation_group,
         state_name,
         total_acres
  FROM (
    SELECT *,
           ROW_NUMBER() OVER (ORDER BY total_acres DESC) AS rn
    FROM forestland_state
  )
  WHERE rn = 1
),

max_timberland AS (                      -- top state for timberland
  SELECT 'TIMBERLAND'                  AS category,
         state_code,
         evaluation_group,
         state_name,
         total_acres
  FROM (
    SELECT *,
           ROW_NUMBER() OVER (ORDER BY total_acres DESC) AS rn
    FROM timberland_state
  )
  WHERE rn = 1
)

SELECT *
FROM max_timberland
UNION ALL
SELECT *
FROM max_forestland
ORDER BY category;