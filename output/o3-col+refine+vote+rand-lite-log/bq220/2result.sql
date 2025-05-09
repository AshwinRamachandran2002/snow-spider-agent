/*  States with the largest average subplot and macroplot sizes
    for 2015-2017 (evaluation_type = 'EXPCURR', condition_status_code = 1)  */

WITH plot_sizes AS (
  /* ----------  Subplots  ---------- */
  SELECT
      c.inventory_year,
      c.state_code_name                     AS state,
      'Subplot'                             AS plot_type,
      p.expansion_factor
    * c.condition_proportion_unadjusted
    * p.adjustment_factor_for_the_subplot   AS size
  FROM `bigquery-public-data.usfs_fia.condition`  AS c
  JOIN `bigquery-public-data.usfs_fia.population` AS p
    ON p.plot_sequence_number = c.plot_sequence_number
   AND p.inventory_year      = c.inventory_year
  WHERE p.evaluation_type              = 'EXPCURR'
    AND c.condition_status_code        = 1
    AND c.proportion_basis             = 'SUBP'
    AND p.adjustment_factor_for_the_subplot  > 0
    AND c.inventory_year IN (2015, 2016, 2017)

  UNION ALL

  /* ----------  Macroplots  ---------- */
  SELECT
      c.inventory_year,
      c.state_code_name                     AS state,
      'Macroplot'                           AS plot_type,
      p.expansion_factor
    * c.condition_proportion_unadjusted
    * p.adjustment_factor_for_the_macroplot AS size
  FROM `bigquery-public-data.usfs_fia.condition`  AS c
  JOIN `bigquery-public-data.usfs_fia.population` AS p
    ON p.plot_sequence_number = c.plot_sequence_number
   AND p.inventory_year      = c.inventory_year
  WHERE p.evaluation_type              = 'EXPCURR'
    AND c.condition_status_code        = 1
    AND c.proportion_basis             = 'MACR'
    AND p.adjustment_factor_for_the_macroplot > 0
    AND c.inventory_year IN (2015, 2016, 2017)
),

avg_by_state AS (
  SELECT
      inventory_year,
      plot_type,
      state,
      AVG(size) AS avg_size
  FROM plot_sizes
  GROUP BY inventory_year, plot_type, state
),

state_max AS (
  SELECT
      inventory_year,
      plot_type,
      state,
      avg_size,
      RANK() OVER (PARTITION BY inventory_year, plot_type
                   ORDER BY avg_size DESC) AS rnk
  FROM avg_by_state
)

SELECT
    plot_type,
    inventory_year AS year,
    state,
    avg_size
FROM state_max
WHERE rnk = 1
ORDER BY plot_type, year;