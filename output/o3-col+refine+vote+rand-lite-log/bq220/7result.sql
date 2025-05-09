--  Largest-average subplot vs. macroplot state for 2015-2017
WITH
/* ---------------------------------------------------------------------
   1.  Compute a “size” (area) value for every qualifying condition row.
       Size formulas follow FIA documentation:
         SUBPLOT  = expansion_factor * condition_prop_unadj * adj_factor_subplot
         MACROPLOT= expansion_factor * condition_prop_unadj * adj_factor_macroplot
   --------------------------------------------------------------------- */
subplot_rows AS (
  SELECT
    c.state_code,
    c.inventory_year,
    (p.expansion_factor *
     c.condition_proportion_unadjusted *
     p.adjustment_factor_for_the_subplot)            AS size_value
  FROM  `bigquery-public-data.usfs_fia.population` AS p
  JOIN  `bigquery-public-data.usfs_fia.condition`  AS c
    ON  p.plot_sequence_number = c.plot_sequence_number
   AND  p.inventory_year       = c.inventory_year
  WHERE p.evaluation_type       = 'EXPCURR'   -- “current-area” evaluations
    AND c.condition_status_code = 1           -- accessible forest land
    AND c.proportion_basis      = 'SUBP'      -- subplot records
    AND c.inventory_year IN (2015, 2016, 2017)
),
macroplot_rows AS (
  SELECT
    c.state_code,
    c.inventory_year,
    (p.expansion_factor *
     c.condition_proportion_unadjusted *
     p.adjustment_factor_for_the_macroplot)          AS size_value
  FROM  `bigquery-public-data.usfs_fia.population` AS p
  JOIN  `bigquery-public-data.usfs_fia.condition`  AS c
    ON  p.plot_sequence_number = c.plot_sequence_number
   AND  p.inventory_year       = c.inventory_year
  WHERE p.evaluation_type       = 'EXPCURR'
    AND c.condition_status_code = 1
    AND c.proportion_basis      = 'MACR'      -- macroplot records
    AND c.inventory_year IN (2015, 2016, 2017)
),

/* ---------------------------------------------------------------------
   2.  Average the size values by state & year for each plot type.
   --------------------------------------------------------------------- */
avg_subplots AS (
  SELECT
    inventory_year,
    state_code,
    AVG(size_value) AS avg_size
  FROM subplot_rows
  GROUP BY inventory_year, state_code
),
avg_macroplots AS (
  SELECT
    inventory_year,
    state_code,
    AVG(size_value) AS avg_size
  FROM macroplot_rows
  GROUP BY inventory_year, state_code
),

/* ---------------------------------------------------------------------
   3.  Pick the state with the largest average for each year & plot type.
   --------------------------------------------------------------------- */
top_subplots AS (
  SELECT
    'SUBPLOT'       AS plot_type,
    inventory_year,
    state_code,
    avg_size,
    ROW_NUMBER() OVER (PARTITION BY inventory_year ORDER BY avg_size DESC) AS rn
  FROM avg_subplots
),
top_macroplots AS (
  SELECT
    'MACROPLOT'     AS plot_type,
    inventory_year,
    state_code,
    avg_size,
    ROW_NUMBER() OVER (PARTITION BY inventory_year ORDER BY avg_size DESC) AS rn
  FROM avg_macroplots
)

/* ---------------------------------------------------------------------
   4.  Final answer ‑- 6 rows (subplot + macroplot winner for each year).
   --------------------------------------------------------------------- */
SELECT
  plot_type,
  inventory_year,
  state_code,
  avg_size AS average_size
FROM (
  SELECT * FROM top_subplots  WHERE rn = 1
  UNION ALL
  SELECT * FROM top_macroplots WHERE rn = 1
)
ORDER BY inventory_year, plot_type;