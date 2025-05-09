/* ------------------------------------------------------------------
   Which state has the greatest number of acres in its most-recent
   EXPCURR evaluation-group?
      •  One answer for FORESTLAND (all condition_status_code = 1)
      •  One answer for TIMBERLAND (condition_status_code = 1
         AND reserved_status_code = 0
         AND site_productivity_class_code BETWEEN 1 AND 6)

   The acreage for every condition is

        proportion_unadjusted
      × expansion_factor
      × adjustment_factor            (use 1 when the adjustment is
                                      NULL or <= 0)

   ‘MACR’  → use macroplot_proportion_unadjusted and the macroplot
   ‘SUBP’  → use subplot_proportion_unadjusted  and the subplot
-------------------------------------------------------------------*/
WITH latest AS (                              -- latest EXPCURR group / state
  SELECT peg.state_code,
         MAX(peg.evaluation_group) AS latest_eval_group
  FROM `bigquery-public-data.usfs_fia.population_evaluation_type`  pet
  JOIN `bigquery-public-data.usfs_fia.population_evaluation_group` peg
    ON pet.evaluation_group_sequence_number = peg.evaluation_group_sequence_number
  WHERE pet.evaluation_type = 'EXPCURR'
  GROUP BY peg.state_code
),
base AS (                                    -- one row per plot in that group
  SELECT DISTINCT
         p.state_code,
         p.evaluation_group,
         p.plot_sequence_number,
         p.stratum_sequence_number,
         p.adjustment_factor_for_the_macroplot,
         p.adjustment_factor_for_the_subplot,
         ps.expansion_factor
  FROM `bigquery-public-data.usfs_fia.population`          p
  JOIN latest l
    ON p.state_code       = l.state_code
   AND p.evaluation_group = l.latest_eval_group
  JOIN `bigquery-public-data.usfs_fia.population_stratum`  ps
    ON p.stratum_sequence_number = ps.stratum_sequence_number
  WHERE p.evaluation_type = 'EXPCURR'
),
cond AS (                                    -- join the conditions
  SELECT
    b.state_code,
    b.evaluation_group,
    c.proportion_basis,
    c.condition_status_code,
    c.reserved_status_code,
    c.site_productivity_class_code,
    c.macroplot_proportion_unadjusted,
    c.subplot_proportion_unadjusted,
    b.expansion_factor,
    b.adjustment_factor_for_the_macroplot,
    b.adjustment_factor_for_the_subplot
  FROM base b
  JOIN `bigquery-public-data.usfs_fia.condition` c
    ON b.plot_sequence_number = c.plot_sequence_number
),
acres_by_state AS (                          -- aggregate acres
  SELECT
    state_code,
    evaluation_group,
    SUM(                                     -- FOREST-land acres
      CASE
        WHEN proportion_basis = 'MACR' THEN
             macroplot_proportion_unadjusted * expansion_factor *
             IFNULL(NULLIF(adjustment_factor_for_the_macroplot,0),1)
        WHEN proportion_basis = 'SUBP' THEN
             subplot_proportion_unadjusted  * expansion_factor *
             IFNULL(NULLIF(adjustment_factor_for_the_subplot ,0),1)
        ELSE 0
      END
    ) AS forestland_acres,
    SUM(                                     -- TIMBER-land acres
      CASE
        WHEN reserved_status_code = 0
         AND site_productivity_class_code BETWEEN 1 AND 6
         AND proportion_basis IN ('MACR','SUBP') THEN
           CASE
             WHEN proportion_basis = 'MACR' THEN
                  macroplot_proportion_unadjusted * expansion_factor *
                  IFNULL(NULLIF(adjustment_factor_for_the_macroplot,0),1)
             WHEN proportion_basis = 'SUBP' THEN
                  subplot_proportion_unadjusted  * expansion_factor *
                  IFNULL(NULLIF(adjustment_factor_for_the_subplot ,0),1)
           END
        ELSE 0
      END
    ) AS timberland_acres
  FROM cond
  WHERE condition_status_code = 1            -- accessible forest land
  GROUP BY state_code, evaluation_group
),
max_forest  AS (SELECT * FROM acres_by_state ORDER BY forestland_acres  DESC LIMIT 1),
max_timber  AS (SELECT * FROM acres_by_state ORDER BY timberland_acres DESC LIMIT 1),
state_names AS (
  SELECT DISTINCT plot_state_code AS state_code,
         plot_state_code_name     AS state_name
  FROM `bigquery-public-data.usfs_fia.plot`
)
SELECT 'FORESTLAND'  AS category,
       f.state_code,
       f.evaluation_group,
       s.state_name,
       f.forestland_acres AS total_acres
FROM max_forest f
JOIN state_names s USING (state_code)

UNION ALL

SELECT 'TIMBERLAND',
       t.state_code,
       t.evaluation_group,
       s.state_name,
       t.timberland_acres
FROM max_timber t
JOIN state_names s USING (state_code);