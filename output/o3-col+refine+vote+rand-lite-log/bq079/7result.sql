/* Top-acreage states (latest EXPCURR evaluation per state) */
WITH latest_eval AS (      -- 1. newest EXPCURR evaluation-sequence for every state
  SELECT ev.state_code,
         ev.evaluation_sequence_number,
         ev.evaluation_group_sequence_number,
         ev.evaluation_identifier,
         ROW_NUMBER() OVER (PARTITION BY ev.state_code
                            ORDER BY ev.evaluation_identifier DESC) AS rn
  FROM `bigquery-public-data.usfs_fia.population_evaluation`      ev
  JOIN `bigquery-public-data.usfs_fia.population_evaluation_type` et
    ON et.evaluation_sequence_number = ev.evaluation_sequence_number
  WHERE et.evaluation_type = 'EXPCURR'
),
latest AS (                 -- keep only the latest
  SELECT state_code,
         evaluation_sequence_number,
         evaluation_group_sequence_number
  FROM   latest_eval
  WHERE  rn = 1
),
acres_base AS (             -- 2. plot-level adjusted expansion acres
  SELECT l.state_code,
         ANY_VALUE(c.state_code_name) AS state_name,
         ANY_VALUE(peg.evaluation_group) AS evaluation_group,
         /* factors & condition fields */
         p.expansion_factor,
         p.adjustment_factor_for_the_macroplot AS adj_macr,
         p.adjustment_factor_for_the_subplot   AS adj_subp,
         c.proportion_basis,
         c.condition_proportion_unadjusted     AS prop_unadj,
         c.condition_status_code,
         c.reserved_status_code,
         c.site_productivity_class_code
  FROM   latest AS l
  JOIN   `bigquery-public-data.usfs_fia.population`            p
         ON p.evaluation_sequence_number = l.evaluation_sequence_number
  JOIN   `bigquery-public-data.usfs_fia.condition`             c
         ON c.plot_sequence_number      = p.plot_sequence_number
  JOIN   `bigquery-public-data.usfs_fia.population_evaluation_group` peg
         ON peg.evaluation_group_sequence_number = l.evaluation_group_sequence_number
  GROUP  BY l.state_code,
           p.expansion_factor,
           adj_macr,
           adj_subp,
           c.proportion_basis,
           prop_unadj,
           c.condition_status_code,
           c.reserved_status_code,
           c.site_productivity_class_code
),
agg AS (                    -- 3. state totals for forest & timber land
  SELECT
    state_code,
    ANY_VALUE(state_name)      AS state_name,
    ANY_VALUE(evaluation_group) AS evaluation_group,
    /* forestland acres */
    SUM(
      IF(condition_status_code = 1,
         CASE
           WHEN proportion_basis = 'MACR' AND adj_macr > 0 THEN expansion_factor * adj_macr
           WHEN proportion_basis = 'SUBP' AND adj_subp > 0 THEN expansion_factor * adj_subp
           ELSE expansion_factor
         END * prop_unadj,
      0)
    ) AS forest_acres,
    /* timberland acres (subset of forestland) */
    SUM(
      IF(condition_status_code = 1
         AND reserved_status_code = 0
         AND site_productivity_class_code BETWEEN 1 AND 6,
         CASE
           WHEN proportion_basis = 'MACR' AND adj_macr > 0 THEN expansion_factor * adj_macr
           WHEN proportion_basis = 'SUBP' AND adj_subp > 0 THEN expansion_factor * adj_subp
           ELSE expansion_factor
         END * prop_unadj,
      0)
    ) AS timber_acres
  FROM acres_base
  GROUP BY state_code
),
winners AS (                -- 4. top state for each category
  SELECT 'TIMBERLAND' AS category, *
  FROM (
    SELECT *, ROW_NUMBER() OVER (ORDER BY timber_acres DESC) AS r
    FROM agg
  )
  WHERE r = 1

  UNION ALL

  SELECT 'FORESTLAND', *
  FROM (
    SELECT *, ROW_NUMBER() OVER (ORDER BY forest_acres DESC) AS r
    FROM agg
  )
  WHERE r = 1
)
SELECT
  category,
  state_code,
  state_name,
  evaluation_group,
  ROUND(timber_acres, 4) AS total_timber_acres,
  ROUND(forest_acres, 4) AS total_forest_acres
FROM winners
ORDER BY category;