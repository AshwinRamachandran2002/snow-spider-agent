/* -----------------------------------------------------------
   Which states have the most forest-land acres and timber-land
   acres (latest “EXPCURR” evaluation-group per state)?
   ----------------------------------------------------------- */
WITH expcurr AS (        -- every state / evaluation_group that has EXPCURR
  SELECT DISTINCT
         peg.state_code,
         peg.evaluation_group
  FROM `bigquery-public-data.usfs_fia.population_evaluation_type`  pet
  JOIN `bigquery-public-data.usfs_fia.population_evaluation`       pe
       ON  pe.evaluation_sequence_number = pet.evaluation_sequence_number
  JOIN `bigquery-public-data.usfs_fia.population_evaluation_group` peg
       ON  peg.evaluation_group_sequence_number = pe.evaluation_group_sequence_number
  WHERE pet.evaluation_type = 'EXPCURR'
),
latest AS (              -- keep only the newest evaluation_group per state
  SELECT state_code, evaluation_group
  FROM (
    SELECT state_code,
           evaluation_group,
           ROW_NUMBER() OVER (PARTITION BY state_code
                              ORDER BY evaluation_group DESC) AS rn
    FROM expcurr)
  WHERE rn = 1
),
acre_totals AS (         -- compute forest-land & timber-land acres
  SELECT
      l.state_code,
      l.evaluation_group,
      SUM(                           -- forest-land acres (cond_status = 1)
        CASE
          WHEN c.proportion_basis = 'MACR' THEN
               p.expansion_factor * c.condition_proportion_unadjusted *
               IFNULL(NULLIF(p.adjustment_factor_for_the_macroplot,0),1)
          WHEN c.proportion_basis = 'SUBP' THEN
               p.expansion_factor * c.condition_proportion_unadjusted *
               IFNULL(NULLIF(p.adjustment_factor_for_the_subplot,0),1)
          ELSE 0
        END )                AS forestland_acres,

      SUM(                           -- timber-land acres (extra filters)
        CASE
          WHEN c.condition_status_code = 1
               AND c.reserved_status_code = 0
               AND c.site_productivity_class_code BETWEEN 1 AND 6
               AND c.proportion_basis IN ('MACR','SUBP')
          THEN CASE
                 WHEN c.proportion_basis = 'MACR' THEN
                      p.expansion_factor * c.condition_proportion_unadjusted *
                      IFNULL(NULLIF(p.adjustment_factor_for_the_macroplot,0),1)
                 WHEN c.proportion_basis = 'SUBP' THEN
                      p.expansion_factor * c.condition_proportion_unadjusted *
                      IFNULL(NULLIF(p.adjustment_factor_for_the_subplot,0),1)
               END
          ELSE 0
        END )                AS timberland_acres
  FROM latest                       l
  JOIN `bigquery-public-data.usfs_fia.population` p
       ON  p.state_code      = l.state_code
       AND p.evaluation_group = l.evaluation_group
  JOIN `bigquery-public-data.usfs_fia.condition`   c
       ON  c.plot_sequence_number = p.plot_sequence_number
       AND c.inventory_year       = p.inventory_year
  WHERE c.condition_status_code = 1               -- must be forest land
  GROUP BY l.state_code, l.evaluation_group
),
max_forest AS ( SELECT * FROM acre_totals ORDER BY forestland_acres DESC LIMIT 1 ),
max_timber AS ( SELECT * FROM acre_totals ORDER BY timberland_acres DESC LIMIT 1 ),

state_names AS (         -- simple lookup for state_code → state_name
  SELECT DISTINCT
         plot_state_code       AS state_code,
         plot_state_code_name  AS state_name
  FROM `bigquery-public-data.usfs_fia.plot`
)

SELECT
  'FORESTLAND'            AS category,
  f.state_code,
  f.evaluation_group,
  sn.state_name,
  f.forestland_acres      AS total_acres
FROM   max_forest f
JOIN   state_names sn USING (state_code)

UNION ALL

SELECT
  'TIMBERLAND'            AS category,
  t.state_code,
  t.evaluation_group,
  sn.state_name,
  t.timberland_acres      AS total_acres
FROM   max_timber t
JOIN   state_names sn USING (state_code);