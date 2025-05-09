WITH base AS (
  -- Live‑forest conditions joined to matching EXPCURR population records
  SELECT
    c.inventory_year AS year,
    c.state_code     AS state,
    CASE
      WHEN c.proportion_basis = 'SUBP' THEN 'Subplot'
      WHEN c.proportion_basis = 'MACR' THEN 'Macroplot'
    END              AS plot_type,
    -- Area per record, respecting “>0 else 0” rule for adjustment factors
    p.expansion_factor
    * c.condition_proportion_unadjusted
    * CASE
        WHEN c.proportion_basis = 'SUBP'
             THEN IF(p.adjustment_factor_for_the_subplot  > 0,
                     p.adjustment_factor_for_the_subplot ,0)
        ELSE        IF(p.adjustment_factor_for_the_macroplot > 0,
                     p.adjustment_factor_for_the_macroplot,0)
      END          AS plot_area
  FROM `bigquery-public-data.usfs_fia.condition`  AS c
  JOIN `bigquery-public-data.usfs_fia.population` AS p
    ON  p.plot_sequence_number = c.plot_sequence_number
   AND p.inventory_year       = c.inventory_year
  WHERE c.condition_status_code = 1
    AND p.evaluation_type      = 'EXPCURR'
    AND c.proportion_basis IN ('SUBP','MACR')
    AND c.inventory_year BETWEEN 2015 AND 2017
),
avg_state AS (
  -- Average size per state, year, and plot type
  SELECT
    plot_type,
    year,
    state,
    AVG(plot_area) AS average_size_acres
  FROM base
  GROUP BY plot_type, year, state
),
winners AS (
  -- State with largest average size for each year & plot type
  SELECT
    plot_type,
    year,
    state,
    average_size_acres,
    ROW_NUMBER() OVER (PARTITION BY plot_type, year
                       ORDER BY average_size_acres DESC) AS rn
  FROM avg_state
)
SELECT
  plot_type,
  year,
  state,
  ROUND(average_size_acres,4) AS average_size_acres
FROM winners
WHERE rn = 1
ORDER BY year, plot_type;