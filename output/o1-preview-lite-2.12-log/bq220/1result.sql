SELECT
  Type,
  Year,
  State,
  ROUND(Average_Size, 4) AS Average_Size
FROM (
  SELECT
    'subplot' AS Type,
    Year,
    State,
    Average_Size
  FROM (
    SELECT
      c.inventory_year AS Year,
      c.state_code AS State,
      AVG(p.expansion_factor * c.condition_proportion_unadjusted * p.adjustment_factor_for_the_subplot) AS Average_Size,
      RANK() OVER (PARTITION BY c.inventory_year ORDER BY AVG(p.expansion_factor * c.condition_proportion_unadjusted * p.adjustment_factor_for_the_subplot) DESC) AS rn
    FROM
      `bigquery-public-data.usfs_fia.condition` AS c
    JOIN
      `bigquery-public-data.usfs_fia.population` AS p
    ON
      c.plot_sequence_number = p.plot_sequence_number
    WHERE
      p.evaluation_type = 'EXPCURR'
      AND c.condition_status_code = 1
      AND c.inventory_year IN (2015, 2016, 2017)
      AND c.proportion_basis = 'SUBP'
      AND p.adjustment_factor_for_the_subplot > 0
    GROUP BY
      c.inventory_year,
      c.state_code
  ) AS t
  WHERE rn = 1

  UNION ALL

  SELECT
    'macroplot' AS Type,
    Year,
    State,
    Average_Size
  FROM (
    SELECT
      c.inventory_year AS Year,
      c.state_code AS State,
      AVG(p.expansion_factor * c.condition_proportion_unadjusted * p.adjustment_factor_for_the_macroplot) AS Average_Size,
      RANK() OVER (PARTITION BY c.inventory_year ORDER BY AVG(p.expansion_factor * c.condition_proportion_unadjusted * p.adjustment_factor_for_the_macroplot) DESC) AS rn
    FROM
      `bigquery-public-data.usfs_fia.condition` AS c
    JOIN
      `bigquery-public-data.usfs_fia.population` AS p
    ON
      c.plot_sequence_number = p.plot_sequence_number
    WHERE
      p.evaluation_type = 'EXPCURR'
      AND c.condition_status_code = 1
      AND c.inventory_year IN (2015, 2016, 2017)
      AND c.proportion_basis = 'MACR'
      AND p.adjustment_factor_for_the_macroplot > 0
    GROUP BY
      c.inventory_year,
      c.state_code
  ) AS t
  WHERE rn = 1
)
ORDER BY
  Type, Year;