WITH subplot_avg AS (
  SELECT
    'SUBPLOT' AS plot_type,
    pop.inventory_year,
    pop.state_code,
    ANY_VALUE(cond.state_code_name) AS state_name,
    -- subplot size: E * P * A_s
    AVG(pop.expansion_factor * cond.condition_proportion_unadjusted
        * pop.adjustment_factor_for_the_subplot) AS avg_size
  FROM `bigquery-public-data.usfs_fia.population`   AS pop
  JOIN `bigquery-public-data.usfs_fia.condition`    AS cond
    ON pop.plot_sequence_number = cond.plot_sequence_number
   AND pop.inventory_year     = cond.inventory_year
  WHERE pop.evaluation_type          = 'EXPCURR'      -- current‑condition evaluation
    AND cond.condition_status_code   = 1              -- accessible forest land
    AND cond.proportion_basis        = 'SUBP'         -- subplot basis
    AND pop.adjustment_factor_for_the_subplot > 0
    AND pop.inventory_year IN (2015, 2016, 2017)
  GROUP BY pop.inventory_year, pop.state_code
),

macroplot_avg AS (
  SELECT
    'MACROPLOT' AS plot_type,
    pop.inventory_year,
    pop.state_code,
    ANY_VALUE(cond.state_code_name) AS state_name,
    -- macroplot size: E * P * A_m
    AVG(pop.expansion_factor * cond.condition_proportion_unadjusted
        * pop.adjustment_factor_for_the_macroplot) AS avg_size
  FROM `bigquery-public-data.usfs_fia.population`   AS pop
  JOIN `bigquery-public-data.usfs_fia.condition`    AS cond
    ON pop.plot_sequence_number = cond.plot_sequence_number
   AND pop.inventory_year     = cond.inventory_year
  WHERE pop.evaluation_type           = 'EXPCURR'
    AND cond.condition_status_code    = 1
    AND cond.proportion_basis         = 'MACR'
    AND pop.adjustment_factor_for_the_macroplot > 0
    AND pop.inventory_year IN (2015, 2016, 2017)
  GROUP BY pop.inventory_year, pop.state_code
),

combined AS (
  SELECT * FROM subplot_avg
  UNION ALL
  SELECT * FROM macroplot_avg
),

ranked AS (
  SELECT
    plot_type,
    inventory_year,
    state_name,
    ROUND(avg_size, 4) AS avg_size,
    ROW_NUMBER() OVER (PARTITION BY plot_type, inventory_year
                       ORDER BY avg_size DESC) AS rn
  FROM combined
)

SELECT
  plot_type,
  inventory_year AS year,
  state_name     AS state,
  avg_size
FROM ranked
WHERE rn = 1
ORDER BY plot_type, year;