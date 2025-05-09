/*  State with the greatest timber-land acres and state with the greatest
    forest-land acres – using each state’s latest EXPCURR evaluation group  */

WITH latest AS (          -- most-recent EXPCURR evaluation group per state
  SELECT peg.state_code,
         MAX(peg.evaluation_group) AS latest_eval_group
  FROM `bigquery-public-data.usfs_fia.population_evaluation_type` pet
  JOIN `bigquery-public-data.usfs_fia.population_evaluation`       pev
    ON pet.evaluation_sequence_number = pev.evaluation_sequence_number
  JOIN `bigquery-public-data.usfs_fia.population_evaluation_group` peg
    ON pev.evaluation_group_sequence_number = peg.evaluation_group_sequence_number
  WHERE pet.evaluation_type = 'EXPCURR'
  GROUP BY peg.state_code
),

pop AS (                  -- population factors for those groups
  SELECT p.plot_sequence_number,
         p.state_code,
         l.latest_eval_group            AS evaluation_group,
         p.expansion_factor,
         p.adjustment_factor_for_the_macroplot AS adj_macr,
         p.adjustment_factor_for_the_subplot  AS adj_subp
  FROM `bigquery-public-data.usfs_fia.population` p
  JOIN latest l
    ON p.state_code       = l.state_code
   AND p.evaluation_group = l.latest_eval_group
),

cond AS (                 -- attach condition info
  SELECT pop.*,
         c.proportion_basis,
         c.macroplot_proportion_unadjusted,
         c.subplot_proportion_unadjusted,
         c.condition_status_code,
         c.reserved_status_code,
         c.site_productivity_class_code
  FROM pop
  JOIN `bigquery-public-data.usfs_fia.condition` c
    ON pop.plot_sequence_number = c.plot_sequence_number
),

acres AS (                -- acres per state (forest-land & timber-land)
  SELECT state_code,
         evaluation_group,

         -- forest-land acres (all status-1 conditions)
         SUM(
           CASE proportion_basis
             WHEN 'MACR' THEN macroplot_proportion_unadjusted * expansion_factor *
                              IF(adj_macr > 0, adj_macr, 1)
             WHEN 'SUBP' THEN subplot_proportion_unadjusted  * expansion_factor *
                              IF(adj_subp > 0, adj_subp, 1)
             ELSE 0
           END
         )                                AS forestland_acres,

         -- timber-land acres (status 1, not-reserved, SPC 1-6)
         SUM(
           CASE
             WHEN condition_status_code = 1
              AND reserved_status_code  = 0
              AND site_productivity_class_code BETWEEN 1 AND 6
               THEN CASE proportion_basis
                      WHEN 'MACR' THEN macroplot_proportion_unadjusted * expansion_factor *
                                       IF(adj_macr > 0, adj_macr, 1)
                      WHEN 'SUBP' THEN subplot_proportion_unadjusted  * expansion_factor *
                                       IF(adj_subp > 0, adj_subp, 1)
                      ELSE 0
                    END
             ELSE 0
           END
         )                                AS timberland_acres
  FROM cond
  WHERE condition_status_code = 1          -- forest-land filter
  GROUP BY state_code, evaluation_group
),

ranked AS (               -- rank states by acreage totals
  SELECT a.*,
         RANK() OVER (ORDER BY timberland_acres  DESC) AS rk_tim,
         RANK() OVER (ORDER BY forestland_acres DESC) AS rk_for
  FROM acres a
),

states AS (               -- lookup: state_code → state name
  SELECT DISTINCT
         plot_state_code                       AS state_code,
         ANY_VALUE(plot_state_code_name)       AS state_name
  FROM `bigquery-public-data.usfs_fia.plot`
  GROUP BY plot_state_code
)

-- final output: one row for timber-land winner, one for forest-land winner
SELECT 'Timberland' AS category,
       r.state_code,
       r.evaluation_group,
       s.state_name,
       r.timberland_acres AS total_acres
FROM ranked r
JOIN states s USING (state_code)
WHERE rk_tim = 1

UNION ALL

SELECT 'Forestland',
       r.state_code,
       r.evaluation_group,
       s.state_name,
       r.forestland_acres
FROM ranked r
JOIN states s USING (state_code)
WHERE rk_for = 1

ORDER BY category;