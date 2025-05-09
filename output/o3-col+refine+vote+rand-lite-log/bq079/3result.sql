/*  State with the greatest acres of  (a) forest-land  and  (b) timber-land
    using only the most-recent “EXPCURR” evaluation group for every state   */

WITH latest AS (          -- newest EXPCURR evaluation-group date per state
  SELECT
    state_code,
    MAX(pop_evaluation_group_created_date) AS max_date
  FROM `bigquery-public-data.usfs_fia.population`
  WHERE evaluation_type = 'EXPCURR'
  GROUP BY state_code
),
pop_curr AS (             -- population rows that belong to those groups
  SELECT
    p.state_code,
    p.evaluation_group,
    p.plot_sequence_number,
    ps.expansion_factor,
    ps.adjustment_factor_for_the_macroplot AS adj_macr,
    ps.adjustment_factor_for_the_subplot   AS adj_subp
  FROM `bigquery-public-data.usfs_fia.population`        AS p
  JOIN latest AS l
    ON p.state_code = l.state_code
   AND p.pop_evaluation_group_created_date = l.max_date
  JOIN `bigquery-public-data.usfs_fia.population_stratum` AS ps
    ON p.stratum_sequence_number = ps.stratum_sequence_number
  WHERE p.evaluation_type = 'EXPCURR'
),
joined AS (              -- add CONDITION information
  SELECT
    pc.state_code,
    pc.evaluation_group,
    c.state_code_name            AS state_name,
    pc.expansion_factor,
    pc.adj_macr,
    pc.adj_subp,
    c.condition_status_code,
    c.reserved_status_code,
    c.site_productivity_class_code,
    c.proportion_basis,
    c.condition_proportion_unadjusted
  FROM pop_curr AS pc
  JOIN `bigquery-public-data.usfs_fia.condition` AS c
    ON pc.plot_sequence_number = c.plot_sequence_number
),
agg AS (                  -- acres per state (latest eval only)
  SELECT
    state_code,
    ANY_VALUE(state_name)        AS state_name,
    evaluation_group,
    -- all forest land (COND_STATUS_CD = 1)
    SUM(
      CASE
        WHEN condition_status_code = 1 THEN
          CASE proportion_basis
               WHEN 'MACR' THEN expansion_factor * condition_proportion_unadjusted *
                               IFNULL(NULLIF(adj_macr,0),1)
               WHEN 'SUBP' THEN expansion_factor * condition_proportion_unadjusted *
                               IFNULL(NULLIF(adj_subp,0),1)
          END
      END
    ) AS forest_acres,
    -- timberland subset of forest land
    SUM(
      CASE
        WHEN condition_status_code = 1
         AND reserved_status_code  = 0
         AND site_productivity_class_code BETWEEN 1 AND 6 THEN
          CASE proportion_basis
               WHEN 'MACR' THEN expansion_factor * condition_proportion_unadjusted *
                               IFNULL(NULLIF(adj_macr,0),1)
               WHEN 'SUBP' THEN expansion_factor * condition_proportion_unadjusted *
                               IFNULL(NULLIF(adj_subp,0),1)
          END
      END
    ) AS timber_acres
  FROM joined
  GROUP BY state_code, evaluation_group
),
ranked AS (               -- rank states by acres for each category
  SELECT
    state_code,
    state_name,
    evaluation_group,
    forest_acres,
    timber_acres,
    RANK() OVER (ORDER BY forest_acres DESC) AS rnk_forest,
    RANK() OVER (ORDER BY timber_acres DESC) AS rnk_timber
  FROM agg
)
-- top-acre state for each category
SELECT 'FORESTLAND' AS category,
       state_code,
       state_name,
       evaluation_group,
       forest_acres AS total_acres
FROM ranked
WHERE rnk_forest = 1

UNION ALL

SELECT 'TIMBERLAND',
       state_code,
       state_name,
       evaluation_group,
       timber_acres
FROM ranked
WHERE rnk_timber = 1;