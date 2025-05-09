-- 1)  Find, for every state, the most‑recent evaluation group that contains
--    the “EXPCURR” (current estimates) evaluation type.
WITH latest_eval_per_state AS (
  SELECT
    state_code,
    MAX(evaluation_group) AS latest_eval_group
  FROM `bigquery-public-data.usfs_fia.population`
  WHERE evaluation_type = 'EXPCURR'
  GROUP BY state_code
),

-- 2)  Bring together the population rows belonging to those latest
--     evaluation groups and join to the CONDITION table so we have the
--     plot/condition level information that determines timber‑/forest‑land.
base AS (
  SELECT
    p.state_code,
    p.evaluation_group,
    c.state_code_name            AS state_name,
    c.condition_status_code,
    c.reserved_status_code,
    c.site_productivity_class_code,
    c.proportion_basis,
    -- proportions (unadjusted)
    c.macroplot_proportion_unadjusted,
    c.subplot_proportion_unadjusted,
    -- stratum‑level expansion & adjustment factors
    p.expansion_factor,
    p.adjustment_factor_for_the_macroplot,
    p.adjustment_factor_for_the_subplot
  FROM `bigquery-public-data.usfs_fia.population`   AS p
  JOIN latest_eval_per_state AS le
       ON p.state_code = le.state_code
      AND p.evaluation_group = le.latest_eval_group
  JOIN `bigquery-public-data.usfs_fia.condition`    AS c
       ON p.plot_sequence_number = c.plot_sequence_number
  WHERE p.evaluation_type = 'EXPCURR'
),

-- 3)  For every condition record, calculate the acreage contribution
--     (expansion factor  ×  condition‑proportion  ×  adjustment factor).
base_with_acres AS (
  SELECT
    state_code,
    evaluation_group,
    state_name,
    condition_status_code,
    reserved_status_code,
    site_productivity_class_code,
    CASE
      WHEN proportion_basis = 'MACR' THEN
        expansion_factor
        * COALESCE(macroplot_proportion_unadjusted,0)
        * CASE
            WHEN COALESCE(adjustment_factor_for_the_macroplot,0) > 0
            THEN adjustment_factor_for_the_macroplot
            ELSE 1
          END
      WHEN proportion_basis = 'SUBP' THEN
        expansion_factor
        * COALESCE(subplot_proportion_unadjusted,0)
        * CASE
            WHEN COALESCE(adjustment_factor_for_the_subplot,0) > 0
            THEN adjustment_factor_for_the_subplot
            ELSE 1
          END
      ELSE 0
    END AS adj_acres
  FROM base
),

-- 4)  Aggregate acres by state/evaluation for Timberland and Forestland.
timberland AS (
  SELECT
    state_code,
    evaluation_group,
    ANY_VALUE(state_name) AS state_name,
    SUM(adj_acres)        AS total_acres
  FROM base_with_acres
  WHERE condition_status_code = 1          -- forest condition
    AND reserved_status_code  = 0          -- not reserved
    AND site_productivity_class_code BETWEEN 1 AND 6
  GROUP BY state_code, evaluation_group
),
forestland AS (
  SELECT
    state_code,
    evaluation_group,
    ANY_VALUE(state_name) AS state_name,
    SUM(adj_acres)        AS total_acres
  FROM base_with_acres
  WHERE condition_status_code = 1          -- forest condition
  GROUP BY state_code, evaluation_group
),

-- 5)  Pick the single state with the greatest acreage for each category.
ranked AS (
  SELECT 'Timberland' AS category, *
         ,ROW_NUMBER() OVER (ORDER BY total_acres DESC) AS rn
  FROM timberland
  UNION ALL
  SELECT 'Forestland' AS category, *
         ,ROW_NUMBER() OVER (ORDER BY total_acres DESC) AS rn
  FROM forestland
)

-- 6)  Return the winners.
SELECT
  category,
  state_code,
  evaluation_group,
  state_name,
  total_acres
FROM ranked
WHERE rn = 1
ORDER BY category;