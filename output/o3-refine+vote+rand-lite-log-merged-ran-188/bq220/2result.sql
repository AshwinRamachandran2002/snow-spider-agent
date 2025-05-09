-- States with the largest average subplot and macroplot size
-- (evaluation_type = 'EXPCURR', condition_status_code = 1)
-- for inventory years 2015‑2017
WITH pop AS (   -- keep one set of expansion / adjustment factors per plot & year
  SELECT
    plot_sequence_number,
    inventory_year,
    ANY_VALUE(expansion_factor)                     AS expansion_factor,
    ANY_VALUE(adjustment_factor_for_the_subplot)    AS adj_subp,
    ANY_VALUE(adjustment_factor_for_the_macroplot)  AS adj_macr
  FROM `bigquery-public-data.usfs_fia.population`
  WHERE evaluation_type = 'EXPCURR'
  GROUP BY plot_sequence_number, inventory_year
),
cond AS (        -- relevant conditions
  SELECT
    plot_sequence_number,
    inventory_year,
    state_code,
    state_code_name,
    proportion_basis,
    condition_proportion_unadjusted
  FROM `bigquery-public-data.usfs_fia.condition`
  WHERE condition_status_code = 1
    AND inventory_year IN (2015, 2016, 2017)
),
joined AS (      -- join conditions to population factors
  SELECT
    c.inventory_year,
    c.state_code,
    c.state_code_name,
    c.proportion_basis,
    c.condition_proportion_unadjusted,
    p.expansion_factor,
    p.adj_subp,
    p.adj_macr
  FROM cond c
  JOIN pop  p
    ON p.plot_sequence_number = c.plot_sequence_number
   AND p.inventory_year      = c.inventory_year
),
sizes AS (       -- average subplot & macroplot size per state & year
  SELECT
    inventory_year,
    state_code,
    state_code_name,
    'SUBPLOT'            AS plot_type,
    AVG(expansion_factor * condition_proportion_unadjusted * adj_subp) AS avg_size
  FROM joined
  WHERE proportion_basis = 'SUBP'
    AND adj_subp  > 0
  GROUP BY inventory_year, state_code, state_code_name

  UNION ALL

  SELECT
    inventory_year,
    state_code,
    state_code_name,
    'MACROPLOT'          AS plot_type,
    AVG(expansion_factor * condition_proportion_unadjusted * adj_macr) AS avg_size
  FROM joined
  WHERE proportion_basis = 'MACR'
    AND adj_macr > 0
  GROUP BY inventory_year, state_code, state_code_name
),
ranked AS (      -- pick the largest average size per year & plot type
  SELECT
    plot_type,
    inventory_year,
    state_code,
    state_code_name,
    avg_size,
    ROW_NUMBER() OVER (PARTITION BY plot_type, inventory_year
                       ORDER BY avg_size DESC) AS rn
  FROM sizes
)
SELECT
  plot_type,
  inventory_year AS year,
  state_code,
  state_code_name AS state,
  avg_size
FROM ranked
WHERE rn = 1
ORDER BY plot_type, year;