/*  Biggest average subplot and macroplot sizes (condition_status_code = 1,
    evaluation_type = 'EXPCURR') for years 2015‑2017                                   */

WITH sizes AS (
  SELECT
    c.inventory_year                                        AS yr,
    c.state_code,
    c.state_code_name                                       AS state,
    
    /* subplot size (only when SUBP basis and valid adjustment factor) */
    CASE
      WHEN c.proportion_basis = 'SUBP'
           AND p.adjustment_factor_for_the_subplot   > 0
      THEN p.expansion_factor
           * c.condition_proportion_unadjusted
           * p.adjustment_factor_for_the_subplot
    END                                                    AS subplot_size,
    
    /* macroplot size (only when MACR basis and valid adjustment factor) */
    CASE
      WHEN c.proportion_basis = 'MACR'
           AND p.adjustment_factor_for_the_macroplot > 0
      THEN p.expansion_factor
           * c.condition_proportion_unadjusted
           * p.adjustment_factor_for_the_macroplot
    END                                                    AS macroplot_size
  FROM `bigquery-public-data.usfs_fia.condition`  AS c
  JOIN `bigquery-public-data.usfs_fia.population` AS p
    ON  p.plot_sequence_number = c.plot_sequence_number
    AND p.inventory_year     = c.inventory_year
    AND p.state_code         = c.state_code
  WHERE c.condition_status_code = 1            -- accessible forest land
    AND p.evaluation_type      = 'EXPCURR'     -- current‑conditions evaluations
    AND c.inventory_year IN (2015, 2016, 2017) -- target years
),

/* average subplot size by state & year */
subplot_avg AS (
  SELECT
    yr,
    state,
    AVG(subplot_size) AS avg_size
  FROM sizes
  WHERE subplot_size IS NOT NULL
  GROUP BY yr, state
),

/* average macroplot size by state & year */
macro_avg AS (
  SELECT
    yr,
    state,
    AVG(macroplot_size) AS avg_size
  FROM sizes
  WHERE macroplot_size IS NOT NULL
  GROUP BY yr, state
),

/* pick state with the largest average in each year */
best_subplot AS (
  SELECT *,
         ROW_NUMBER() OVER (PARTITION BY yr ORDER BY avg_size DESC) AS rk
  FROM subplot_avg
),
best_macro AS (
  SELECT *,
         ROW_NUMBER() OVER (PARTITION BY yr ORDER BY avg_size DESC) AS rk
  FROM macro_avg
)

SELECT
  'SUBPLOT'                    AS plot_type,
  yr                           AS year,
  state,
  avg_size                     AS average_size
FROM best_subplot
WHERE rk = 1

UNION ALL

SELECT
  'MACROPLOT'                  AS plot_type,
  yr                           AS year,
  state,
  avg_size                     AS average_size
FROM best_macro
WHERE rk = 1

ORDER BY year, plot_type;