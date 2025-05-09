WITH area_data AS (
  SELECT
    'subplot' AS Type,
    c.inventory_year AS Year,
    c.state_code_name AS State,
    (p.expansion_factor * c.condition_proportion_unadjusted * p.adjustment_factor_for_the_subplot) AS Average_Size
  FROM
    `bigquery-public-data.usfs_fia.condition` AS c
  JOIN
    `bigquery-public-data.usfs_fia.population` AS p
  ON
    c.plot_sequence_number = p.plot_sequence_number
  WHERE
    c.condition_status_code = 1
    AND c.proportion_basis = 'SUBP'
    AND c.inventory_year IN (2015, 2016, 2017)
    AND p.evaluation_type = 'EXPCURR'
    AND p.adjustment_factor_for_the_subplot > 0

  UNION ALL

  SELECT
    'macroplot' AS Type,
    c.inventory_year AS Year,
    c.state_code_name AS State,
    (p.expansion_factor * c.condition_proportion_unadjusted * p.adjustment_factor_for_the_macroplot) AS Average_Size
  FROM
    `bigquery-public-data.usfs_fia.condition` AS c
  JOIN
    `bigquery-public-data.usfs_fia.population` AS p
  ON
    c.plot_sequence_number = p.plot_sequence_number
  WHERE
    c.condition_status_code = 1
    AND c.proportion_basis = 'MACR'
    AND c.inventory_year IN (2015, 2016, 2017)
    AND p.evaluation_type = 'EXPCURR'
    AND p.adjustment_factor_for_the_macroplot > 0
),

averages AS (
  SELECT
    Type,
    Year,
    State,
    AVG(Average_Size) AS Average_Size
  FROM
    area_data
  GROUP BY
    Type,
    Year,
    State
),

ranked AS (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY Type, Year ORDER BY Average_Size DESC) AS rn
  FROM
    averages
)

SELECT
  Type,
  Year,
  State,
  Average_Size
FROM
  ranked
WHERE
  rn = 1
ORDER BY
  Type,
  Year