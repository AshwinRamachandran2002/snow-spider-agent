WITH average_subplot_sizes AS (
  SELECT
    c.state_code,
    c.state_code_name AS State,
    c.inventory_year AS Year,
    AVG(c.condition_proportion_unadjusted * p.expansion_factor * p.adjustment_factor_for_the_subplot) AS Average_Size
  FROM
    `bigquery-public-data.usfs_fia.condition` AS c
  JOIN
    `bigquery-public-data.usfs_fia.population` AS p
  ON
    c.plot_sequence_number = p.plot_sequence_number
  JOIN
    `bigquery-public-data.usfs_fia.population_evaluation_type` AS pet
  ON
    p.evaluation_type_sequence_number = pet.evaluation_type_sequence_number
  WHERE
    c.proportion_basis = 'SUBP'
    AND c.condition_status_code_name = 'Accessible forest land'
    AND c.inventory_year IN (2015, 2016, 2017)
    AND pet.evaluation_type = 'EXPCURR'
    AND c.condition_proportion_unadjusted > 0
    AND p.expansion_factor > 0
    AND p.adjustment_factor_for_the_subplot > 0
  GROUP BY
    c.state_code,
    State,
    Year
),
average_macroplot_sizes AS (
  SELECT
    c.state_code,
    c.state_code_name AS State,
    c.inventory_year AS Year,
    AVG(c.condition_proportion_unadjusted * p.expansion_factor * p.adjustment_factor_for_the_macroplot) AS Average_Size
  FROM
    `bigquery-public-data.usfs_fia.condition` AS c
  JOIN
    `bigquery-public-data.usfs_fia.population` AS p
  ON
    c.plot_sequence_number = p.plot_sequence_number
  JOIN
    `bigquery-public-data.usfs_fia.population_evaluation_type` AS pet
  ON
    p.evaluation_type_sequence_number = pet.evaluation_type_sequence_number
  WHERE
    c.proportion_basis = 'MACR'
    AND c.condition_status_code_name = 'Accessible forest land'
    AND c.inventory_year IN (2015, 2016, 2017)
    AND pet.evaluation_type = 'EXPCURR'
    AND c.condition_proportion_unadjusted > 0
    AND p.expansion_factor > 0
    AND p.adjustment_factor_for_the_macroplot > 0
  GROUP BY
    c.state_code,
    State,
    Year
),
largest_subplot_per_year AS (
  SELECT
    'subplot' AS Type_of_Plot,
    Year,
    State,
    Average_Size
  FROM (
    SELECT
      *,
      ROW_NUMBER() OVER (PARTITION BY Year ORDER BY Average_Size DESC) AS rn
    FROM
      average_subplot_sizes
  )
  WHERE
    rn = 1
),
largest_macroplot_per_year AS (
  SELECT
    'macroplot' AS Type_of_Plot,
    Year,
    State,
    Average_Size
  FROM (
    SELECT
      *,
      ROW_NUMBER() OVER (PARTITION BY Year ORDER BY Average_Size DESC) AS rn
    FROM
      average_macroplot_sizes
  )
  WHERE
    rn = 1
)
SELECT
  Type_of_Plot,
  Year,
  State,
  Average_Size
FROM
  largest_subplot_per_year
UNION ALL
SELECT
  Type_of_Plot,
  Year,
  State,
  Average_Size
FROM
  largest_macroplot_per_year
ORDER BY
  Type_of_Plot,
  Year;