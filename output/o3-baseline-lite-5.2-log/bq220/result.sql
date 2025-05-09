--  State with the largest average subplot‑size and macroplot‑size
--  (condition_status_code = 1, evaluation_type = 'EXPCURR')
--  for inventory years 2015‑2017
WITH sizes AS (
  SELECT
      c.inventory_year                                           AS yr,
      c.state_code,
      COALESCE(c.state_code_name, CONCAT('State_',c.state_code)) AS state_name,
      /* subplot size */
      CASE
        WHEN c.proportion_basis = 'SUBP'
             AND p.adjustment_factor_for_the_subplot > 0
        THEN p.expansion_factor
             * c.condition_proportion_unadjusted
             * p.adjustment_factor_for_the_subplot
        ELSE 0
      END                                                       AS subplot_size,
      /* macroplot size */
      CASE
        WHEN c.proportion_basis = 'MACR'
             AND p.adjustment_factor_for_the_macroplot > 0
        THEN p.expansion_factor
             * c.condition_proportion_unadjusted
             * p.adjustment_factor_for_the_macroplot
        ELSE 0
      END                                                       AS macroplot_size
  FROM   `bigquery-public-data.usfs_fia.population` p
  JOIN   `bigquery-public-data.usfs_fia.condition`  c
         ON  p.plot_sequence_number = c.plot_sequence_number
         AND p.inventory_year     = c.inventory_year
  WHERE  p.evaluation_type      = 'EXPCURR'
    AND  c.condition_status_code = 1           -- accessible forest land
    AND  c.inventory_year IN (2015,2016,2017)
),

avg_sz AS (      -- average sizes per state & year
  SELECT
      yr,
      state_code,
      ANY_VALUE(state_name)                            AS state_name,
      AVG(subplot_size)                                AS avg_subplot_size,
      AVG(macroplot_size)                              AS avg_macroplot_size
  FROM  sizes
  GROUP BY yr, state_code
),

best_subplot AS (          -- state with largest average subplot size
  SELECT
      'subplot'                 AS plot_type,
      yr                        AS year,
      state_name,
      ROUND(avg_subplot_size,4) AS avg_size,
      ROW_NUMBER() OVER (PARTITION BY yr
                         ORDER BY avg_subplot_size DESC) AS rn
  FROM  avg_sz
),

best_macro AS (             -- state with largest average macroplot size
  SELECT
      'macroplot'               AS plot_type,
      yr                        AS year,
      state_name,
      ROUND(avg_macroplot_size,4) AS avg_size,
      ROW_NUMBER() OVER (PARTITION BY yr
                         ORDER BY avg_macroplot_size DESC) AS rn
  FROM  avg_sz
)

SELECT plot_type,
       year,
       state_name,
       avg_size
FROM  (
        SELECT * FROM best_subplot WHERE rn = 1
        UNION ALL
        SELECT * FROM best_macro  WHERE rn = 1
      )
ORDER BY year, plot_type;