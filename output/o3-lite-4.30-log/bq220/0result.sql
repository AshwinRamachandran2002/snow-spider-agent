/* Largest‑average subplot and macroplot sizes by state
   for inventory years 2015‑2017 under EXPCURR evaluations */

WITH joined AS (
  SELECT
    p.inventory_year,
    c.state_code,
    c.proportion_basis,
    p.expansion_factor,
    c.condition_proportion_unadjusted,
    p.adjustment_factor_for_the_subplot   AS adj_subplot,
    p.adjustment_factor_for_the_macroplot AS adj_macroplot
  FROM `bigquery-public-data.usfs_fia.population` AS p
  JOIN `bigquery-public-data.usfs_fia.condition`  AS c
    ON p.plot_sequence_number = c.plot_sequence_number
   AND p.inventory_year       = c.inventory_year
  WHERE p.evaluation_type       = 'EXPCURR'
    AND c.condition_status_code = 1
    AND p.inventory_year IN (2015, 2016, 2017)
),

-- average subplot size per state/year
subplot AS (
  SELECT
    inventory_year,
    state_code,
    AVG(expansion_factor * condition_proportion_unadjusted * adj_subplot) AS avg_size
  FROM joined
  WHERE proportion_basis = 'SUBP'
    AND adj_subplot > 0
  GROUP BY inventory_year, state_code
),
subplot_rank AS (
  SELECT
    'subplot'      AS plot_type,
    inventory_year AS year,
    state_code     AS state,
    avg_size,
    ROW_NUMBER() OVER (PARTITION BY inventory_year ORDER BY avg_size DESC) AS rn
  FROM subplot
),

-- average macroplot size per state/year
macroplot AS (
  SELECT
    inventory_year,
    state_code,
    AVG(expansion_factor * condition_proportion_unadjusted * adj_macroplot) AS avg_size
  FROM joined
  WHERE proportion_basis = 'MACR'
    AND adj_macroplot > 0
  GROUP BY inventory_year, state_code
),
macroplot_rank AS (
  SELECT
    'macroplot'    AS plot_type,
    inventory_year AS year,
    state_code     AS state,
    avg_size,
    ROW_NUMBER() OVER (PARTITION BY inventory_year ORDER BY avg_size DESC) AS rn
  FROM macroplot
)

SELECT
  plot_type,
  year,
  state,
  ROUND(avg_size, 4) AS average_size_acres
FROM (
  SELECT * FROM subplot_rank
  UNION ALL
  SELECT * FROM macroplot_rank
)
WHERE rn = 1
ORDER BY year, plot_type;