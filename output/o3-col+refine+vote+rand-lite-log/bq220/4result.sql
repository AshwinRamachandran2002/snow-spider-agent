WITH subplot AS (
  SELECT
    'Subplot' AS plot_type,
    c.inventory_year AS year,
    c.state_code_name AS state,
    AVG(p.expansion_factor *
        c.condition_proportion_unadjusted *
        p.adjustment_factor_for_the_subplot) AS avg_size,
    RANK() OVER (
      PARTITION BY c.inventory_year
      ORDER BY AVG(p.expansion_factor *
                   c.condition_proportion_unadjusted *
                   p.adjustment_factor_for_the_subplot) DESC
    ) AS rnk
  FROM `bigquery-public-data.usfs_fia.condition`  AS c
  JOIN `bigquery-public-data.usfs_fia.population` AS p
    ON p.plot_sequence_number = c.plot_sequence_number
   AND p.inventory_year     = c.inventory_year
  WHERE p.evaluation_type           = 'EXPCURR'
    AND c.condition_status_code     = 1
    AND c.inventory_year IN (2015, 2016, 2017)
    AND c.proportion_basis          = 'SUBP'
    AND p.adjustment_factor_for_the_subplot > 0
  GROUP BY year, state
),
macroplot AS (
  SELECT
    'Macroplot' AS plot_type,
    c.inventory_year AS year,
    c.state_code_name AS state,
    AVG(p.expansion_factor *
        c.condition_proportion_unadjusted *
        p.adjustment_factor_for_the_macroplot) AS avg_size,
    RANK() OVER (
      PARTITION BY c.inventory_year
      ORDER BY AVG(p.expansion_factor *
                   c.condition_proportion_unadjusted *
                   p.adjustment_factor_for_the_macroplot) DESC
    ) AS rnk
  FROM `bigquery-public-data.usfs_fia.condition`  AS c
  JOIN `bigquery-public-data.usfs_fia.population` AS p
    ON p.plot_sequence_number = c.plot_sequence_number
   AND p.inventory_year     = c.inventory_year
  WHERE p.evaluation_type            = 'EXPCURR'
    AND c.condition_status_code      = 1
    AND c.inventory_year  IN (2015, 2016, 2017)
    AND c.proportion_basis           = 'MACR'
    AND p.adjustment_factor_for_the_macroplot > 0
  GROUP BY year, state
)

SELECT
  plot_type,
  year,
  state,
  ROUND(avg_size, 4) AS avg_size
FROM (
  SELECT * FROM subplot  WHERE rnk = 1
  UNION ALL
  SELECT * FROM macroplot WHERE rnk = 1
)
ORDER BY year, plot_type;