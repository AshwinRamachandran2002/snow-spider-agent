/*  -------------------------------------------------------------
    Timberland & Forestland acreage – state with greatest total
    -------------------------------------------------------------
    – “Latest evaluation group per state” is taken as the most
      recent (largest END_INVENTORY_YEAR) population‐evaluation
      whose evaluation‑type = 'EXPCURR'.
    – Acres for a condition  = EXPANSION_FACTOR              *
                                relevant ADJUSTMENT_FACTOR    *
                                (macroplot when PROPORTION_BASIS='MACR',
                                 subplot   when PROPORTION_BASIS='SUBP').
      If the chosen adjustment factor is NULL or ≤0 we treat it as 1.
----------------------------------------------------------------- */
WITH latest_eval AS (
  SELECT
      pe.state_code,
      pe.evaluation_group_sequence_number
  FROM  `bigquery-public-data.usfs_fia.population_evaluation`       pe
  JOIN  `bigquery-public-data.usfs_fia.population_evaluation_type`  pet
           ON pet.evaluation_sequence_number = pe.evaluation_sequence_number
  WHERE pet.evaluation_type = 'EXPCURR'
  QUALIFY ROW_NUMBER() OVER (PARTITION BY pe.state_code
                             ORDER BY CAST(pe.end_inventory_year AS INT64) DESC) = 1
),
/* plots used in the most‑recent EXPCURR evaluation for each state */
pop AS (
  SELECT
      p.plot_sequence_number,
      p.inventory_year,
      p.state_code,
      p.expansion_factor,
      p.adjustment_factor_for_the_macroplot,
      p.adjustment_factor_for_the_subplot,
      p.evaluation_group
  FROM  `bigquery-public-data.usfs_fia.population`  p
  JOIN  latest_eval  le
           ON le.evaluation_group_sequence_number = p.evaluation_group_sequence_number
  WHERE p.evaluation_type = 'EXPCURR'
),
/* per‑condition acres (macroplot & subplot only, forest land) */
cond_acres AS (
  SELECT
      p.state_code,
      c.state_code_name                     AS state_name,
      p.evaluation_group,
      CASE c.proportion_basis
           WHEN 'MACR' THEN p.expansion_factor
                         * IFNULL(NULLIF(p.adjustment_factor_for_the_macroplot ,0),1)
           WHEN 'SUBP' THEN p.expansion_factor
                         * IFNULL(NULLIF(p.adjustment_factor_for_the_subplot ,0),1)
           ELSE 0
      END                                   AS acres,
      c.reserved_status_code,
      c.site_productivity_class_code
  FROM  pop  p
  JOIN  `bigquery-public-data.usfs_fia.condition`  c
           ON  c.plot_sequence_number = p.plot_sequence_number
           AND c.inventory_year      = p.inventory_year
  WHERE c.condition_status_code = 1               -- forest land
    AND c.proportion_basis IN ('MACR','SUBP')     -- use only macro / subplot
),
/* --- Forest land totals --------------------------------------------------- */
forest_tot AS (
  SELECT
      state_code,
      ANY_VALUE(state_name)     AS state_name,
      ANY_VALUE(evaluation_group) AS evaluation_group,
      SUM(acres)                AS total_acres
  FROM cond_acres
  GROUP BY state_code
),
/* --- Timber land totals --------------------------------------------------- */
timber_tot AS (
  SELECT
      state_code,
      ANY_VALUE(state_name)     AS state_name,
      ANY_VALUE(evaluation_group) AS evaluation_group,
      SUM(acres)                AS total_acres
  FROM cond_acres
  WHERE reserved_status_code = 0
    AND site_productivity_class_code BETWEEN 1 AND 6
  GROUP BY state_code
),
max_forest AS (
  SELECT * FROM forest_tot
  ORDER BY total_acres DESC
  LIMIT 1
),
max_timber AS (
  SELECT * FROM timber_tot
  ORDER BY total_acres DESC
  LIMIT 1
)
/* ------------------------------- final answer ------------------------------- */
SELECT
    'FORESTLAND'      AS category,
    state_code,
    evaluation_group,
    state_name,
    total_acres
FROM max_forest
UNION ALL
SELECT
    'TIMBERLAND'      AS category,
    state_code,
    evaluation_group,
    state_name,
    total_acres
FROM max_timber;