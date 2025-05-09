/*  State with the greatest acreage of
    • TIMBERLAND (status = 1, not-reserved, site class 1-6)
    • FORESTLAND (status = 1)
    using only the *latest* EXPCURR evaluation-group per state              */

WITH latest AS (           -- newest “EXPCURR” evaluation-group for every state
  SELECT
      eg.state_code,
      eg.evaluation_group_sequence_number,
      eg.evaluation_group,
      ROW_NUMBER() OVER (PARTITION BY eg.state_code
                         ORDER BY SAFE_CAST(REGEXP_EXTRACT(eg.evaluation_group_description,
                                                           r'(\d{4})') AS INT64) DESC) AS rn
  FROM `bigquery-public-data.usfs_fia.population_evaluation_group`   AS eg
  JOIN `bigquery-public-data.usfs_fia.population_evaluation_type`    AS et
        ON et.evaluation_group_sequence_number = eg.evaluation_group_sequence_number
  WHERE et.evaluation_type = 'EXPCURR'
), chosen AS (
  SELECT state_code, evaluation_group_sequence_number, evaluation_group
  FROM   latest
  WHERE  rn = 1
),                            -- bring in plots, strata & conditions
base AS (
  SELECT
      ch.state_code,
      ch.evaluation_group,
      c.proportion_basis,
      ps.expansion_factor,
      c.condition_proportion_unadjusted,
      ps.adjustment_factor_for_the_macroplot AS adj_macr,
      ps.adjustment_factor_for_the_subplot   AS adj_subp,
      c.condition_status_code,
      c.reserved_status_code,
      c.site_productivity_class_code
  FROM   chosen                                          AS ch
  JOIN   `bigquery-public-data.usfs_fia.population`      AS p
         ON p.evaluation_group_sequence_number = ch.evaluation_group_sequence_number
  JOIN   `bigquery-public-data.usfs_fia.condition`       AS c
         ON c.plot_sequence_number = p.plot_sequence_number
  JOIN   `bigquery-public-data.usfs_fia.population_stratum` AS ps
         ON ps.stratum_sequence_number = p.stratum_sequence_number
), acres AS (         -- compute acres for each land-class
  -- TIMBERLAND
  SELECT
      state_code,
      evaluation_group,
      'TIMBERLAND' AS landclass,
      SUM(
        CASE
          WHEN proportion_basis = 'MACR' AND adj_macr > 0
               THEN expansion_factor * condition_proportion_unadjusted * adj_macr
          WHEN proportion_basis = 'SUBP' AND adj_subp > 0
               THEN expansion_factor * condition_proportion_unadjusted * adj_subp
        END) AS acres
  FROM base
  WHERE condition_status_code = 1
    AND reserved_status_code  = 0
    AND site_productivity_class_code BETWEEN 1 AND 6
  GROUP BY state_code, evaluation_group

  UNION ALL

  -- FORESTLAND
  SELECT
      state_code,
      evaluation_group,
      'FORESTLAND' AS landclass,
      SUM(
        CASE
          WHEN proportion_basis = 'MACR' AND adj_macr > 0
               THEN expansion_factor * condition_proportion_unadjusted * adj_macr
          WHEN proportion_basis = 'SUBP' AND adj_subp > 0
               THEN expansion_factor * condition_proportion_unadjusted * adj_subp
        END) AS acres
  FROM base
  WHERE condition_status_code = 1
  GROUP BY state_code, evaluation_group
), ranked AS (        -- pick the single top-acreage state inside each land-class
  SELECT
      a.*,
      ROW_NUMBER() OVER (PARTITION BY landclass ORDER BY acres DESC) AS rk
  FROM acres a
), state_names AS (
  SELECT DISTINCT
         plot_state_code AS state_code,
         plot_state_code_name AS state_name
  FROM `bigquery-public-data.usfs_fia.plot`
  WHERE plot_state_code_name IS NOT NULL
)
SELECT
    r.state_code,
    r.evaluation_group,         -- evaluation group number
    sn.state_name,
    r.landclass,
    r.acres
FROM   ranked r
LEFT JOIN state_names sn USING (state_code)
WHERE  rk = 1
ORDER  BY landclass;