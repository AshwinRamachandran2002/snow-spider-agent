/* ------------------------------------------------------------
   State with the greatest acreage of
   • FORESTLAND  (cond_status = 1)
   • TIMBERLAND (cond_status = 1, reserved = 0, site prod 1-6)
   – restricted to each state’s most-recent EXPCURR evaluation
   – acres = Σ( expansion_factor × adjustment_factor )
             using MACR or SUBP proportion bases
   ------------------------------------------------------------ */
WITH latest_eval AS (          -- newest “EXPCURR” evaluation-id per state
  SELECT pe.state_code,
         MAX(pe.evaluation_identifier) AS latest_eval_id
  FROM   `bigquery-public-data.usfs_fia.population_evaluation`       AS pe
  JOIN   `bigquery-public-data.usfs_fia.population_evaluation_type`  AS pet
    ON   pet.evaluation_sequence_number = pe.evaluation_sequence_number
  WHERE  pet.evaluation_type = 'EXPCURR'
  GROUP  BY pe.state_code
)
, base AS (                    -- population rows tied to that evaluation
  SELECT p.state_code,
         p.expansion_factor,
         p.adjustment_factor_for_the_macroplot AS adj_macr,
         p.adjustment_factor_for_the_subplot   AS adj_subp,
         c.proportion_basis,
         c.condition_status_code,
         c.reserved_status_code,
         c.site_productivity_class_code,
         c.state_code_name                AS state_name
  FROM   `bigquery-public-data.usfs_fia.population`  AS p
  JOIN   latest_eval  le
         ON le.state_code      = p.state_code
        AND le.latest_eval_id  = p.evaluation_identifier
  JOIN   `bigquery-public-data.usfs_fia.condition`   AS c
         ON c.plot_sequence_number = p.plot_sequence_number
)
, forest AS (                  -- forestland acres per state
  SELECT state_code,
         ANY_VALUE(state_name) AS state_name,
         SUM(
           CASE
             WHEN proportion_basis = 'MACR' AND adj_macr > 0
               THEN expansion_factor * adj_macr
             WHEN proportion_basis = 'SUBP' AND adj_subp > 0
               THEN expansion_factor * adj_subp
             ELSE 0
           END
         ) AS total_acres
  FROM   base
  WHERE  condition_status_code = 1
  GROUP  BY state_code
)
, timber AS (                  -- timberland acres per state
  SELECT state_code,
         ANY_VALUE(state_name) AS state_name,
         SUM(
           CASE
             WHEN proportion_basis = 'MACR' AND adj_macr > 0
               THEN expansion_factor * adj_macr
             WHEN proportion_basis = 'SUBP' AND adj_subp > 0
               THEN expansion_factor * adj_subp
             ELSE 0
           END
         ) AS total_acres
  FROM   base
  WHERE  condition_status_code = 1
    AND  reserved_status_code  = 0
    AND  site_productivity_class_code BETWEEN 1 AND 6
  GROUP  BY state_code
)
, forest_top AS (              -- top state for forestland
  SELECT
    'FORESTLAND' AS category,
    f.state_code,
    ( SELECT MAX(evaluation_group)
        FROM `bigquery-public-data.usfs_fia.population_evaluation_group`
       WHERE state_code = f.state_code )           AS evaluation_group,
    f.state_name,
    f.total_acres
  FROM forest AS f
  ORDER BY f.total_acres DESC
  LIMIT 1
)
, timber_top AS (              -- top state for timberland
  SELECT
    'TIMBERLAND' AS category,
    t.state_code,
    ( SELECT MAX(evaluation_group)
        FROM `bigquery-public-data.usfs_fia.population_evaluation_group`
       WHERE state_code = t.state_code )           AS evaluation_group,
    t.state_name,
    t.total_acres
  FROM timber AS t
  ORDER BY t.total_acres DESC
  LIMIT 1
)
SELECT * FROM forest_top
UNION ALL
SELECT * FROM timber_top;