/* -----------------------------------------------------------
   Highest-acreage states (latest EXPCURR evaluation per state)
   – one row for Forestland (status = 1)
   – one row for Timberland (status =1, reserved =0, SPC 1-6)
   ----------------------------------------------------------- */
WITH latest_eval AS (                     -- newest evaluation_group per state
  SELECT
    state_code,
    MAX(evaluation_group) AS evaluation_group
  FROM `bigquery-public-data.usfs_fia.population_evaluation_group`
  GROUP BY state_code
),
expcurr_plots AS (                        -- plots that belong to that eval
  SELECT DISTINCT
    p.plot_sequence_number,
    p.state_code,
    p.evaluation_group,
    p.stratum_sequence_number
  FROM `bigquery-public-data.usfs_fia.population` AS p
  JOIN latest_eval                AS le
    ON  p.state_code       = le.state_code
   AND p.evaluation_group  = le.evaluation_group
  WHERE p.evaluation_type = 'EXPCURR'
),
cond_join AS (                            -- attach condition data we need
  SELECT
    ep.state_code,
    ep.evaluation_group,
    ep.plot_sequence_number,
    ep.stratum_sequence_number,
    c.condition_status_code,
    c.reserved_status_code,
    c.site_productivity_class_code,
    c.proportion_basis,
    c.condition_proportion_unadjusted
  FROM expcurr_plots                       AS ep
  JOIN `bigquery-public-data.usfs_fia.condition` AS c
    ON c.plot_sequence_number = ep.plot_sequence_number
),
acres AS (                                -- convert each condition to acres
  SELECT
    cj.state_code,
    cj.evaluation_group,
    CASE
      WHEN cj.proportion_basis = 'MACR'
        THEN ps.expansion_factor
             * IFNULL(NULLIF(ps.adjustment_factor_for_the_macroplot ,0),1)
             * cj.condition_proportion_unadjusted
      WHEN cj.proportion_basis = 'SUBP'
        THEN ps.expansion_factor
             * IFNULL(NULLIF(ps.adjustment_factor_for_the_subplot  ,0),1)
             * cj.condition_proportion_unadjusted
      ELSE ps.expansion_factor * cj.condition_proportion_unadjusted
    END                                                         AS area_acres,
    cj.condition_status_code,
    cj.reserved_status_code,
    cj.site_productivity_class_code
  FROM cond_join                               AS cj
  JOIN `bigquery-public-data.usfs_fia.population_stratum` AS ps
    ON  ps.stratum_sequence_number = cj.stratum_sequence_number
),
state_sums AS (                           -- sum acres by state & evaluation
  SELECT
    state_code,
    evaluation_group,
    SUM(IF(condition_status_code = 1, area_acres, 0))                        AS forest_acres,
    SUM(
        IF(condition_status_code = 1
           AND reserved_status_code = 0
           AND site_productivity_class_code BETWEEN 1 AND 6,
           area_acres, 0)                                                    ) AS timber_acres
  FROM acres
  GROUP BY state_code, evaluation_group
),
top_forest AS ( SELECT * FROM state_sums ORDER BY forest_acres  DESC LIMIT 1 ),
top_timber AS ( SELECT * FROM state_sums ORDER BY timber_acres  DESC LIMIT 1 ),
state_names AS (                         -- quick lookup of state names
  SELECT DISTINCT plot_state_code AS state_code,
                  plot_state_code_name AS state_name
  FROM `bigquery-public-data.usfs_fia.plot`
)
-- final two-row report
SELECT
  'FORESTLAND'           AS category,
  tf.state_code,
  sn.state_name,
  tf.evaluation_group,
  tf.forest_acres        AS total_acres
FROM top_forest tf
LEFT JOIN state_names sn USING (state_code)

UNION ALL

SELECT
  'TIMBERLAND'           AS category,
  tt.state_code,
  sn.state_name,
  tt.evaluation_group,
  tt.timber_acres        AS total_acres
FROM top_timber tt
LEFT JOIN state_names sn USING (state_code);