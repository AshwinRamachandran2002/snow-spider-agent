/* ---------------------------------------------------------------
   State with the greatest TIMBERLAND acres
   and state with the greatest FORESTLAND acres
   (based on the latest EXPCURR evaluation group per state)
-----------------------------------------------------------------*/
WITH latest_eval AS (             -- most‑recent evaluation_group per state
  SELECT
    state_code,
    MAX(evaluation_group) AS evaluation_group
  FROM `bigquery-public-data.usfs_fia.population`
  WHERE evaluation_type = 'EXPCURR'
  GROUP BY state_code
),
pop_dedup AS (                    -- one record per plot within those groups
  SELECT
    p.state_code,
    p.evaluation_group,
    p.plot_sequence_number,
    MAX(p.expansion_factor)                                            AS expansion_factor,
    MAX(COALESCE(NULLIF(p.adjustment_factor_for_the_macroplot ,0),1))  AS adj_macro,
    MAX(COALESCE(NULLIF(p.adjustment_factor_for_the_subplot ,0),1))    AS adj_subp
  FROM `bigquery-public-data.usfs_fia.population` p
  JOIN latest_eval l
    ON p.state_code       = l.state_code
   AND p.evaluation_group = l.evaluation_group
  WHERE p.evaluation_type = 'EXPCURR'
  GROUP BY p.state_code, p.evaluation_group, p.plot_sequence_number
),
cond AS (                         -- usable condition records
  SELECT
    plot_sequence_number,
    proportion_basis,                     -- 'MACR' or 'SUBP'
    condition_proportion_unadjusted,
    reserved_status_code,
    site_productivity_class_code
  FROM `bigquery-public-data.usfs_fia.condition`
  WHERE condition_status_code = 1
    AND proportion_basis IN ('MACR','SUBP')
),
calc AS (                         -- acreage contribution per plot‑condition
  SELECT
    pp.state_code,
    pp.evaluation_group,
    -- forestland acres
    CASE
      WHEN c.proportion_basis = 'MACR'
           THEN pp.expansion_factor * pp.adj_macro * c.condition_proportion_unadjusted
      ELSE  pp.expansion_factor * pp.adj_subp  * c.condition_proportion_unadjusted
    END                                                               AS forest_part,
    -- timberland acres (extra filters)
    CASE
      WHEN c.reserved_status_code = 0
       AND c.site_productivity_class_code BETWEEN 1 AND 6
      THEN CASE
             WHEN c.proportion_basis = 'MACR'
                  THEN pp.expansion_factor * pp.adj_macro * c.condition_proportion_unadjusted
             ELSE pp.expansion_factor * pp.adj_subp  * c.condition_proportion_unadjusted
           END
    END                                                               AS timber_part
  FROM pop_dedup pp
  JOIN cond     c
    ON pp.plot_sequence_number = c.plot_sequence_number
),
state_totals AS (                 -- summed acres per state / evaluation group
  SELECT
    state_code,
    evaluation_group,
    SUM(forest_part)  AS forest_acres,
    SUM(timber_part)  AS timber_acres
  FROM calc
  GROUP BY state_code, evaluation_group
),
top_forest AS (                   -- state with greatest forestland
  SELECT *
  FROM state_totals
  ORDER BY forest_acres DESC
  LIMIT 1
),
top_timber AS (                   -- state with greatest timberland
  SELECT *
  FROM state_totals
  ORDER BY timber_acres DESC
  LIMIT 1
),
state_names AS (                  -- translate code → name
  SELECT DISTINCT
         plot_state_code      AS state_code,
         plot_state_code_name AS state_name
  FROM `bigquery-public-data.usfs_fia.plot`
)
SELECT 'TIMBERLAND'                      AS category,
       t.state_code                      AS state_cd,
       t.evaluation_group                AS evalidgrp,
       n.state_name,
       ROUND(t.timber_acres ,4)          AS total_acres
FROM top_timber t
LEFT JOIN state_names n USING (state_code)

UNION ALL

SELECT 'FORESTLAND'                     AS category,
       f.state_code                     AS state_cd,
       f.evaluation_group               AS evalidgrp,
       n.state_name,
       ROUND(f.forest_acres,4)          AS total_acres
FROM top_forest f
LEFT JOIN state_names n USING (state_code);