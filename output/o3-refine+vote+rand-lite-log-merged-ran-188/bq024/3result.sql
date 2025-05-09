/*  Top-10 evaluation-groups of “2012” by their largest subplot acres               */
/*  – keep only the single condition with the greatest subplot acres per group      */

WITH cond_rank AS (
  SELECT
    p.evaluation_group,                       -- group id
    et.evaluation_type,                       -- e.g. EXPCURR, EXPVOL …
    c.condition_status_code,                  -- 1=forest,2=non-forest, etc.
    ev.evaluation_description,                -- human-readable title
    p.state_code,                             -- state
    c.macroplot_proportion_unadjusted
        * p.expansion_factor        AS macroplot_acres,
    c.subplot_proportion_unadjusted
        * p.expansion_factor        AS subplot_acres,

    ROW_NUMBER() OVER (PARTITION BY p.evaluation_group
                       ORDER BY
                       c.subplot_proportion_unadjusted
                       * p.expansion_factor DESC) AS rn
  FROM  `bigquery-public-data.usfs_fia.population`                 AS p
  JOIN  `bigquery-public-data.usfs_fia.condition`                  AS c
        ON  c.plot_sequence_number = p.plot_sequence_number
  JOIN  `bigquery-public-data.usfs_fia.population_evaluation`      AS ev
        ON  ev.evaluation_sequence_number = p.evaluation_sequence_number
  JOIN  `bigquery-public-data.usfs_fia.population_evaluation_type` AS et
        ON  et.evaluation_sequence_number = ev.evaluation_sequence_number
  /*  limit to evaluations that include calendar-year 2012  */
  WHERE ev.report_year_name LIKE '%2012%'
)

SELECT
  evaluation_group,
  evaluation_type,
  condition_status_code,
  evaluation_description,
  state_code,
  ROUND(macroplot_acres ,4) AS macroplot_acres,
  ROUND(subplot_acres ,4)  AS subplot_acres
FROM   cond_rank
WHERE  rn = 1                      -- keep the biggest-subplot-acres condition per group
ORDER  BY subplot_acres DESC
LIMIT  10;