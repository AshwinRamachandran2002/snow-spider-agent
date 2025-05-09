/*  Largest average subplot- and macroplot-sizes
    for each year (2015-2017) under EXPCURR evaluation            */

WITH base AS (
  SELECT
    c.inventory_year                                                    AS year,
    c.state_code_name                                                   AS state,
    c.proportion_basis,
    p.expansion_factor,
    c.condition_proportion_unadjusted                                   AS prop_unadj,
    p.adjustment_factor_for_the_subplot                                 AS adj_subp,
    p.adjustment_factor_for_the_macroplot                               AS adj_macr
  FROM `bigquery-public-data.usfs_fia.condition`  AS c
  JOIN `bigquery-public-data.usfs_fia.population` AS p
    ON  c.plot_sequence_number = p.plot_sequence_number
    AND c.inventory_year     = p.inventory_year
  WHERE c.condition_status_code = 1            -- “Accessible forest land”
    AND p.evaluation_type     = 'EXPCURR'
    AND c.inventory_year IN (2015, 2016, 2017)
),

-- average subplot size per state & year
subplots AS (
  SELECT
    'SUBPLOT'                       AS plot_type,
    year,
    state,
    AVG(expansion_factor * prop_unadj * adj_subp) AS avg_size
  FROM base
  WHERE proportion_basis = 'SUBP'
    AND adj_subp         > 0
  GROUP BY year, state
),

-- average macroplot size per state & year
macroplots AS (
  SELECT
    'MACROPLOT'                     AS plot_type,
    year,
    state,
    AVG(expansion_factor * prop_unadj * adj_macr) AS avg_size
  FROM base
  WHERE proportion_basis = 'MACR'
    AND adj_macr         > 0
  GROUP BY year, state
),

-- combine and rank within each plot type & year
ranked AS (
  SELECT *,
         ROW_NUMBER() OVER (PARTITION BY plot_type, year
                            ORDER BY avg_size DESC) AS rn
  FROM (
    SELECT * FROM subplots
    UNION ALL
    SELECT * FROM macroplots
  )
)

SELECT
  plot_type,
  year,
  state,
  avg_size AS average_size
FROM ranked
WHERE rn = 1
ORDER BY plot_type, year;