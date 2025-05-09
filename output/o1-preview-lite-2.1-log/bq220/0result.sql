WITH plot_data AS (
  SELECT
    c.state_code_name AS State,
    c.inventory_year AS Year,
    CASE
      WHEN c.proportion_basis = 'SUBP' THEN 'subplot'
      WHEN c.proportion_basis = 'MACR' THEN 'macroplot'
    END AS Type_of_Plot,
    c.condition_proportion_unadjusted AS P,
    p.expansion_factor AS E,
    p.adjustment_factor_for_the_subplot AS A_s,
    p.adjustment_factor_for_the_macroplot AS A_m
  FROM
    `bigquery-public-data.usfs_fia.condition` AS c
  JOIN
    `bigquery-public-data.usfs_fia.population` AS p
  ON
    c.plot_sequence_number = p.plot_sequence_number
  WHERE
    c.condition_status_code = 1  -- Accessible forest land
    AND p.evaluation_type = 'EXPCURR'  -- Current evaluations
    AND c.inventory_year IN (2015, 2016, 2017)
    AND c.proportion_basis IN ('SUBP', 'MACR')
    AND (
      (c.proportion_basis = 'SUBP' AND p.adjustment_factor_for_the_subplot > 0)
      OR
      (c.proportion_basis = 'MACR' AND p.adjustment_factor_for_the_macroplot > 0)
    )
),
plot_areas AS (
  SELECT
    Type_of_Plot,
    Year,
    State,
    CASE
      WHEN Type_of_Plot = 'subplot' THEN E * P * A_s
      WHEN Type_of_Plot = 'macroplot' THEN E * P * A_m
      ELSE NULL
    END AS Plot_Area
  FROM
    plot_data
),
average_plot_size AS (
  SELECT
    Type_of_Plot,
    Year,
    State,
    AVG(Plot_Area) AS Average_Size
  FROM
    plot_areas
  GROUP BY
    Type_of_Plot, Year, State
),
ranked_plot_size AS (
  SELECT
    Type_of_Plot,
    Year,
    State,
    Average_Size,
    ROW_NUMBER() OVER(PARTITION BY Type_of_Plot, Year ORDER BY Average_Size DESC) AS rn
  FROM
    average_plot_size
)
SELECT
  Type_of_Plot,
  Year,
  State,
  ROUND(Average_Size, 4) AS Average_Size
FROM
  ranked_plot_size
WHERE
  rn = 1
ORDER BY
  Type_of_Plot, Year;