/* ----------------------------------------------------------------------
   Highest‑acreage states (latest EXPCURR evaluation per state)
   • Timberland  – cond_status =1, reserved =0, site_prod 1‑6
   • Forestland – cond_status =1
   Result: one row per category showing state with greatest acres
------------------------------------------------------------------------ */
WITH latest AS (   -- most‑recent EXPCURR evaluation for every state
  SELECT
    pe.state_code,
    pe.location_name                        AS state_name,
    pe.evaluation_sequence_number,
    peg.evaluation_group
  FROM `bigquery-public-data.usfs_fia.population_evaluation_type` pet
  JOIN `bigquery-public-data.usfs_fia.population_evaluation`       pe
    ON pe.evaluation_sequence_number = pet.evaluation_sequence_number
  JOIN `bigquery-public-data.usfs_fia.population_evaluation_group` peg
    ON peg.evaluation_group_sequence_number = pe.evaluation_group_sequence_number
  WHERE pet.evaluation_type = 'EXPCURR'
  QUALIFY ROW_NUMBER() OVER (PARTITION BY pe.state_code
                             ORDER BY CAST(pe.end_inventory_year AS INT64) DESC,
                                      pe.evaluation_identifier     DESC) = 1
),
/* ---------- helper to convert plot/condition to acres --------------- */
calc_acres AS (
  SELECT
    l.state_code,
    l.state_name,
    l.evaluation_group,
    c.condition_status_code,
    c.reserved_status_code,
    c.site_productivity_class_code,
    c.proportion_basis,
    c.condition_proportion_unadjusted                    AS prop_unadj,
    p.expansion_factor                                   AS exp_fac,
    IFNULL(NULLIF(p.adjustment_factor_for_the_macroplot,0),1)  AS adj_macr,
    IFNULL(NULLIF(p.adjustment_factor_for_the_subplot ,0),1)   AS adj_subp
  FROM latest AS l
  JOIN `bigquery-public-data.usfs_fia.population` AS p
    ON p.evaluation_sequence_number = l.evaluation_sequence_number
  JOIN `bigquery-public-data.usfs_fia.condition`  AS c
    ON c.plot_sequence_number = p.plot_sequence_number
),
forest AS (        -- acres of forest land
  SELECT
    'Forestland'            AS category,
    state_code,
    state_name,
    evaluation_group,
    SUM(
      CASE proportion_basis
           WHEN 'MACR' THEN prop_unadj * exp_fac * adj_macr
           WHEN 'SUBP' THEN prop_unadj * exp_fac * adj_subp
           ELSE 0
      END
    ) / 43560.0             AS total_acres
  FROM calc_acres
  WHERE condition_status_code = 1
  GROUP BY category, state_code, state_name, evaluation_group
),
timber AS (        -- acres of timber land
  SELECT
    'Timberland'           AS category,
    state_code,
    state_name,
    evaluation_group,
    SUM(
      CASE proportion_basis
           WHEN 'MACR' THEN prop_unadj * exp_fac * adj_macr
           WHEN 'SUBP' THEN prop_unadj * exp_fac * adj_subp
           ELSE 0
      END
    ) / 43560.0            AS total_acres
  FROM calc_acres
  WHERE condition_status_code = 1
    AND reserved_status_code = 0
    AND site_productivity_class_code BETWEEN 1 AND 6
  GROUP BY category, state_code, state_name, evaluation_group
),
top_forest AS ( SELECT * FROM forest ORDER BY total_acres DESC LIMIT 1 ),
top_timber AS ( SELECT * FROM timber ORDER BY total_acres DESC LIMIT 1 )

SELECT * FROM top_timber
UNION ALL
SELECT * FROM top_forest;