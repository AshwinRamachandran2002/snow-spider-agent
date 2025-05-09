/*  States with the largest average SUBPLOT size
    and the largest average MACROPLOT size for
    each of the years 2015-2017 (evaluation_type = 'EXPCURR',
    condition_status_code = 1)                                         */
WITH
/* ---------- average subplot size per state & year ---------- */
subplot_avg AS (
  SELECT
    c.inventory_year,
    c.state_code_name                   AS state,
    AVG(
      CASE
        WHEN c.proportion_basis = 'SUBP'
         AND p.adjustment_factor_for_the_subplot > 0
        THEN p.expansion_factor
             * c.condition_proportion_unadjusted
             * p.adjustment_factor_for_the_subplot
      END
    )                                   AS avg_size
  FROM `bigquery-public-data.usfs_fia.condition`  AS c
  JOIN `bigquery-public-data.usfs_fia.population` AS p
    ON  p.plot_sequence_number = c.plot_sequence_number
    AND p.inventory_year       = c.inventory_year
  WHERE p.evaluation_type       = 'EXPCURR'
    AND c.condition_status_code = 1
    AND c.inventory_year BETWEEN 2015 AND 2017
  GROUP BY c.inventory_year, c.state_code_name
),
/* ---------- average macroplot size per state & year ---------- */
macroplot_avg AS (
  SELECT
    c.inventory_year,
    c.state_code_name                   AS state,
    AVG(
      CASE
        WHEN c.proportion_basis = 'MACR'
         AND p.adjustment_factor_for_the_macroplot > 0
        THEN p.expansion_factor
             * c.condition_proportion_unadjusted
             * p.adjustment_factor_for_the_macroplot
      END
    )                                   AS avg_size
  FROM `bigquery-public-data.usfs_fia.condition`  AS c
  JOIN `bigquery-public-data.usfs_fia.population` AS p
    ON  p.plot_sequence_number = c.plot_sequence_number
    AND p.inventory_year       = c.inventory_year
  WHERE p.evaluation_type       = 'EXPCURR'
    AND c.condition_status_code = 1
    AND c.inventory_year BETWEEN 2015 AND 2017
  GROUP BY c.inventory_year, c.state_code_name
),
/* ---------- pick the single largest state per year ---------- */
top_sub AS (
  SELECT
    'SUBPLOT'          AS plot_type,
    inventory_year     AS year,
    state,
    avg_size,
    ROW_NUMBER() OVER (PARTITION BY inventory_year
                       ORDER BY avg_size DESC) AS rn
  FROM subplot_avg
),
top_mac AS (
  SELECT
    'MACROPLOT'        AS plot_type,
    inventory_year     AS year,
    state,
    avg_size,
    ROW_NUMBER() OVER (PARTITION BY inventory_year
                       ORDER BY avg_size DESC) AS rn
  FROM macroplot_avg
)
/* ----------------------- final output ----------------------- */
SELECT plot_type,
       year,
       state,
       avg_size
FROM (
  SELECT * FROM top_sub WHERE rn = 1
  UNION ALL
  SELECT * FROM top_mac WHERE rn = 1
)
ORDER BY year, plot_type;