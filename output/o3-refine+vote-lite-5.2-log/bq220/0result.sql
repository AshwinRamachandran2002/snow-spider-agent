/*  States with the largest average subplot‑size and macroplot‑size
    for each year (2015‑2017) when
      – evaluation_type = 'EXPCURR'
      – condition_status_code = 1                                             */

WITH joined AS (           -- link population information to plot‑condition rows
  SELECT
      p.plot_sequence_number,
      p.inventory_year                       AS year,
      p.state_code,
      c.state_code_name                      AS state_name,
      p.expansion_factor,
      p.adjustment_factor_for_the_subplot    AS adj_subp,
      p.adjustment_factor_for_the_macroplot  AS adj_macr,
      c.condition_proportion_unadjusted      AS prop_unadj,
      c.proportion_basis
  FROM `bigquery-public-data.usfs_fia.population` p
  JOIN `bigquery-public-data.usfs_fia.condition`   c
       ON  p.plot_sequence_number = c.plot_sequence_number
       AND p.inventory_year       = c.inventory_year
       AND p.state_code           = c.state_code
  WHERE p.evaluation_type      = 'EXPCURR'
    AND c.condition_status_code = 1              -- accessible forest land
    AND c.inventory_year IN (2015, 2016, 2017)
),

calc AS (                -- compute subplot and macroplot size for every record
  SELECT
      year,
      state_code,
      state_name,
      CASE
        WHEN proportion_basis = 'SUBP'
             AND COALESCE(adj_subp,0) > 0
        THEN COALESCE(expansion_factor,0)
             * COALESCE(prop_unadj,0)
             * COALESCE(adj_subp,0)
        ELSE 0
      END  AS subplot_size,
      CASE
        WHEN proportion_basis = 'MACR'
             AND COALESCE(adj_macr,0) > 0
        THEN COALESCE(expansion_factor,0)
             * COALESCE(prop_unadj,0)
             * COALESCE(adj_macr,0)
        ELSE 0
      END  AS macroplot_size
  FROM joined
),

avg_sizes AS (           -- average size per state & year
  SELECT
      year,
      state_code,
      MAX(state_name)                   AS state_name,
      AVG(subplot_size)    AS avg_subplot_size,
      AVG(macroplot_size)  AS avg_macroplot_size
  FROM calc
  GROUP BY year, state_code
),

rank_sub AS (            -- state with largest average subplot size each year
  SELECT
      'subplot'           AS plot_type,
      year,
      state_name          AS state,
      avg_subplot_size    AS avg_size,
      ROW_NUMBER() OVER (PARTITION BY year
                         ORDER BY avg_subplot_size DESC) AS rn
  FROM avg_sizes
),

rank_macr AS (           -- state with largest average macroplot size each year
  SELECT
      'macroplot'         AS plot_type,
      year,
      state_name          AS state,
      avg_macroplot_size  AS avg_size,
      ROW_NUMBER() OVER (PARTITION BY year
                         ORDER BY avg_macroplot_size DESC) AS rn
  FROM avg_sizes
)

SELECT plot_type,
       year,
       state,
       avg_size
FROM (
  SELECT * FROM rank_sub  WHERE rn = 1
  UNION ALL
  SELECT * FROM rank_macr WHERE rn = 1
)
ORDER BY year, plot_type;