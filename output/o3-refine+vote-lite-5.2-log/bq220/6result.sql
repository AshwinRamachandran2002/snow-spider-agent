--  Largest average subplot and macroplot size (current‑area evaluations, accessible forest land)
WITH pop_factors AS (   -- keep one set of factors per plot that belongs to an EXPCURR evaluation
  SELECT
    plot_sequence_number,
    ANY_VALUE(expansion_factor)                       AS expansion_factor,
    ANY_VALUE(adjustment_factor_for_the_subplot)      AS adj_subplot,
    ANY_VALUE(adjustment_factor_for_the_macroplot)    AS adj_macroplot
  FROM `bigquery-public-data.usfs_fia.population`
  WHERE evaluation_type = 'EXPCURR'
  GROUP BY plot_sequence_number
),
base AS (              -- compute subplot / macroplot size for each condition record
  SELECT
    c.inventory_year                       AS yr,
    IFNULL(c.state_code_name,
           CAST(c.state_code AS STRING))   AS state,
    -- subplot size
    CASE
      WHEN c.proportion_basis = 'SUBP'
           AND pf.adj_subplot > 0
      THEN pf.expansion_factor
           * c.condition_proportion_unadjusted
           * pf.adj_subplot
    END                                    AS subplot_size,
    -- macroplot size
    CASE
      WHEN c.proportion_basis = 'MACR'
           AND pf.adj_macroplot > 0
      THEN pf.expansion_factor
           * c.condition_proportion_unadjusted
           * pf.adj_macroplot
    END                                    AS macroplot_size
  FROM `bigquery-public-data.usfs_fia.condition` c
  JOIN pop_factors pf
    ON c.plot_sequence_number = pf.plot_sequence_number
  WHERE c.condition_status_code = 1                 -- accessible forest land
    AND c.inventory_year IN (2015, 2016, 2017)      -- target years
),
avg_sizes AS (         -- average size by state, year, and plot type
  SELECT 'Subplot' AS plot_type, yr, state,
         AVG(subplot_size) AS avg_size
  FROM base
  WHERE subplot_size IS NOT NULL
  GROUP BY yr, state

  UNION ALL

  SELECT 'Macroplot',  yr, state,
         AVG(macroplot_size)
  FROM base
  WHERE macroplot_size IS NOT NULL
  GROUP BY yr, state
),
ranked AS (            -- rank states by average size (largest = 1) per year & type
  SELECT
    plot_type,
    yr,
    state,
    avg_size,
    ROW_NUMBER() OVER (
      PARTITION BY plot_type, yr
      ORDER BY avg_size DESC
    ) AS rn
  FROM avg_sizes
)
SELECT
  plot_type,
  yr  AS year,
  state,
  ROUND(avg_size, 4) AS average_size
FROM ranked
WHERE rn = 1           -- keep only the largest average per year & plot type
ORDER BY plot_type, year;