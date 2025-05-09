--  Largest average subplot‑size and macroplot‑size, by year (2015‑2017)
--    • restrict to evaluation_type  = 'EXPCURR'
--    • restrict to condition_status_code = 1  (accessible forest land)
--    • subplot size  =  E × P × A_s      when proportion_basis = 'SUBP'
--    • macroplot size = E × P × A_m      when proportion_basis = 'MACR'

WITH joined AS (
  SELECT
      c.inventory_year                                        AS yr,
      c.state_code_name                                       AS state,
      c.proportion_basis,
      c.condition_proportion_unadjusted                       AS P,
      pop.expansion_factor                                    AS E,
      pop.adjustment_factor_for_the_subplot                   AS A_s,
      pop.adjustment_factor_for_the_macroplot                 AS A_m
  FROM  `bigquery-public-data.usfs_fia.condition`  AS c
  JOIN  `bigquery-public-data.usfs_fia.population` AS pop
        ON  pop.plot_sequence_number = c.plot_sequence_number
        AND pop.inventory_year      = c.inventory_year
        AND pop.state_code          = c.state_code
        AND pop.evaluation_type     = 'EXPCURR'
  WHERE c.condition_status_code = 1                       -- accessible forest land
        AND c.inventory_year IN (2015,2016,2017)
),

sizes AS (
  SELECT
      yr,
      state,
      /* subplot size */
      CASE WHEN proportion_basis = 'SUBP' AND A_s > 0
           THEN E * P * A_s
      END                                                 AS subplot_size,
      /* macroplot size */
      CASE WHEN proportion_basis = 'MACR' AND A_m > 0
           THEN E * P * A_m
      END                                                 AS macroplot_size
  FROM joined
),

avg_state AS (
  SELECT
      yr,
      state,
      AVG(subplot_size)   AS avg_subplot_size,
      AVG(macroplot_size) AS avg_macroplot_size
  FROM sizes
  GROUP BY yr, state
),

best_subplot AS (
  SELECT
      'subplot'        AS plot_type,
      yr               AS year,
      state,
      avg_subplot_size AS avg_size,
      RANK() OVER (PARTITION BY yr ORDER BY avg_subplot_size DESC) AS rnk
  FROM avg_state
  WHERE avg_subplot_size IS NOT NULL
),

best_macroplot AS (
  SELECT
      'macroplot'      AS plot_type,
      yr               AS year,
      state,
      avg_macroplot_size AS avg_size,
      RANK() OVER (PARTITION BY yr ORDER BY avg_macroplot_size DESC) AS rnk
  FROM avg_state
  WHERE avg_macroplot_size IS NOT NULL
)

SELECT plot_type, year, state, avg_size
FROM (
      SELECT * FROM best_subplot  WHERE rnk = 1
      UNION ALL
      SELECT * FROM best_macroplot WHERE rnk = 1
)
ORDER BY year, plot_type;