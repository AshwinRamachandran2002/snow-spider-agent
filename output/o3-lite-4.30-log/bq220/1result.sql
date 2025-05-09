WITH subplot AS (
  SELECT
    'SUBPLOT' AS plot_type,
    p.inventory_year                               AS year,
    p.state_code                                   AS state,
    AVG(p.expansion_factor *
        c.condition_proportion_unadjusted *
        p.adjustment_factor_for_the_subplot)       AS avg_size
  FROM `bigquery-public-data.usfs_fia.population`  AS p
  JOIN `bigquery-public-data.usfs_fia.condition`   AS c
    ON p.plot_sequence_number = c.plot_sequence_number
   AND p.inventory_year      = c.inventory_year
  WHERE p.evaluation_type               = 'EXPCURR'
    AND p.inventory_year IN (2015, 2016, 2017)
    AND c.condition_status_code         = 1
    AND c.proportion_basis              = 'SUBP'
    AND p.adjustment_factor_for_the_subplot > 0
  GROUP BY year, state
),
macroplot AS (
  SELECT
    'MACROPLOT' AS plot_type,
    p.inventory_year                               AS year,
    p.state_code                                   AS state,
    AVG(p.expansion_factor *
        c.condition_proportion_unadjusted *
        p.adjustment_factor_for_the_macroplot)     AS avg_size
  FROM `bigquery-public-data.usfs_fia.population`  AS p
  JOIN `bigquery-public-data.usfs_fia.condition`   AS c
    ON p.plot_sequence_number = c.plot_sequence_number
   AND p.inventory_year      = c.inventory_year
  WHERE p.evaluation_type               = 'EXPCURR'
    AND p.inventory_year IN (2015, 2016, 2017)
    AND c.condition_status_code         = 1
    AND c.proportion_basis              = 'MACR'
    AND p.adjustment_factor_for_the_macroplot > 0
  GROUP BY year, state
),
ranked AS (
  SELECT
    plot_type,
    year,
    state,
    avg_size,
    ROW_NUMBER() OVER (PARTITION BY plot_type, year ORDER BY avg_size DESC) AS rn
  FROM (
    SELECT * FROM subplot
    UNION ALL
    SELECT * FROM macroplot
  )
)
SELECT
  plot_type,
  year,
  state,
  ROUND(avg_size, 4) AS average_size_acres
FROM ranked
WHERE rn = 1
ORDER BY year, plot_type;