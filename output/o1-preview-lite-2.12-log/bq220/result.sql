WITH state_mapping AS (
  SELECT 1 AS state_code, 'Alabama' AS State UNION ALL
  SELECT 2, 'Alaska' UNION ALL
  SELECT 4, 'Arizona' UNION ALL
  SELECT 5, 'Arkansas' UNION ALL
  SELECT 6, 'California' UNION ALL
  SELECT 8, 'Colorado' UNION ALL
  SELECT 9, 'Connecticut' UNION ALL
  SELECT 10, 'Delaware' UNION ALL
  SELECT 12, 'Florida' UNION ALL
  SELECT 13, 'Georgia' UNION ALL
  SELECT 15, 'Hawaii' UNION ALL
  SELECT 16, 'Idaho' UNION ALL
  SELECT 17, 'Illinois' UNION ALL
  SELECT 18, 'Indiana' UNION ALL
  SELECT 19, 'Iowa' UNION ALL
  SELECT 20, 'Kansas' UNION ALL
  SELECT 21, 'Kentucky' UNION ALL
  SELECT 22, 'Louisiana' UNION ALL
  SELECT 23, 'Maine' UNION ALL
  SELECT 24, 'Maryland' UNION ALL
  SELECT 25, 'Massachusetts' UNION ALL
  SELECT 26, 'Michigan' UNION ALL
  SELECT 27, 'Minnesota' UNION ALL
  SELECT 28, 'Mississippi' UNION ALL
  SELECT 29, 'Missouri' UNION ALL
  SELECT 30, 'Montana' UNION ALL
  SELECT 31, 'Nebraska' UNION ALL
  SELECT 32, 'Nevada' UNION ALL
  SELECT 33, 'New Hampshire' UNION ALL
  SELECT 34, 'New Jersey' UNION ALL
  SELECT 35, 'New Mexico' UNION ALL
  SELECT 36, 'New York' UNION ALL
  SELECT 37, 'North Carolina' UNION ALL
  SELECT 38, 'North Dakota' UNION ALL
  SELECT 39, 'Ohio' UNION ALL
  SELECT 40, 'Oklahoma' UNION ALL
  SELECT 41, 'Oregon' UNION ALL
  SELECT 42, 'Pennsylvania' UNION ALL
  SELECT 44, 'Rhode Island' UNION ALL
  SELECT 45, 'South Carolina' UNION ALL
  SELECT 46, 'South Dakota' UNION ALL
  SELECT 47, 'Tennessee' UNION ALL
  SELECT 48, 'Texas' UNION ALL
  SELECT 49, 'Utah' UNION ALL
  SELECT 50, 'Vermont' UNION ALL
  SELECT 51, 'Virginia' UNION ALL
  SELECT 53, 'Washington' UNION ALL
  SELECT 54, 'West Virginia' UNION ALL
  SELECT 55, 'Wisconsin' UNION ALL
  SELECT 56, 'Wyoming' UNION ALL
  SELECT 72, 'Puerto Rico'
)

SELECT
  Type,
  Year,
  State,
  ROUND(Average_Size, 4) AS Average_Size
FROM (
  SELECT
    result.Type,
    result.Year,
    sm.State,
    result.Average_Size
  FROM (
    -- Compute average sizes per state per year for subplot and macroplot
    SELECT
      'subplot' AS Type,
      p.measurement_year AS Year,
      c.state_code,
      AVG(pop.expansion_factor * c.condition_proportion_unadjusted * pop.adjustment_factor_for_the_subplot) AS Average_Size
    FROM
      `bigquery-public-data.usfs_fia.condition` AS c
    JOIN
      `bigquery-public-data.usfs_fia.plot` AS p
        ON c.plot_sequence_number = p.plot_sequence_number
    JOIN
      `bigquery-public-data.usfs_fia.population` AS pop
        ON c.plot_sequence_number = pop.plot_sequence_number
    WHERE
      p.measurement_year IN (2015, 2016, 2017)
      AND c.condition_status_code = 1
      AND pop.evaluation_type = 'EXPCURR'
      AND c.proportion_basis = 'SUBP'
      AND pop.adjustment_factor_for_the_subplot > 0
      AND pop.expansion_factor IS NOT NULL
      AND c.condition_proportion_unadjusted IS NOT NULL
    GROUP BY
      p.measurement_year,
      c.state_code

    UNION ALL

    SELECT
      'macroplot' AS Type,
      p.measurement_year AS Year,
      c.state_code,
      AVG(pop.expansion_factor * c.condition_proportion_unadjusted * pop.adjustment_factor_for_the_macroplot) AS Average_Size
    FROM
      `bigquery-public-data.usfs_fia.condition` AS c
    JOIN
      `bigquery-public-data.usfs_fia.plot` AS p
        ON c.plot_sequence_number = p.plot_sequence_number
    JOIN
      `bigquery-public-data.usfs_fia.population` AS pop
        ON c.plot_sequence_number = pop.plot_sequence_number
    WHERE
      p.measurement_year IN (2015, 2016, 2017)
      AND c.condition_status_code = 1
      AND pop.evaluation_type = 'EXPCURR'
      AND c.proportion_basis = 'MACR'
      AND pop.adjustment_factor_for_the_macroplot > 0
      AND pop.expansion_factor IS NOT NULL
      AND c.condition_proportion_unadjusted IS NOT NULL
    GROUP BY
      p.measurement_year,
      c.state_code
  ) AS result
  JOIN state_mapping AS sm
    ON result.state_code = sm.state_code
  JOIN (
    SELECT
      Type,
      Year,
      MAX(Average_Size) AS Max_Average_Size
    FROM (
      -- Compute average sizes per state per year for subplot and macroplot
      SELECT
        'subplot' AS Type,
        p.measurement_year AS Year,
        c.state_code,
        AVG(pop.expansion_factor * c.condition_proportion_unadjusted * pop.adjustment_factor_for_the_subplot) AS Average_Size
      FROM
        `bigquery-public-data.usfs_fia.condition` AS c
      JOIN
        `bigquery-public-data.usfs_fia.plot` AS p
          ON c.plot_sequence_number = p.plot_sequence_number
      JOIN
        `bigquery-public-data.usfs_fia.population` AS pop
          ON c.plot_sequence_number = pop.plot_sequence_number
      WHERE
        p.measurement_year IN (2015, 2016, 2017)
        AND c.condition_status_code = 1
        AND pop.evaluation_type = 'EXPCURR'
        AND c.proportion_basis = 'SUBP'
        AND pop.adjustment_factor_for_the_subplot > 0
        AND pop.expansion_factor IS NOT NULL
        AND c.condition_proportion_unadjusted IS NOT NULL
      GROUP BY
        p.measurement_year,
        c.state_code

      UNION ALL

      SELECT
        'macroplot' AS Type,
        p.measurement_year AS Year,
        c.state_code,
        AVG(pop.expansion_factor * c.condition_proportion_unadjusted * pop.adjustment_factor_for_the_macroplot) AS Average_Size
      FROM
        `bigquery-public-data.usfs_fia.condition` AS c
      JOIN
        `bigquery-public-data.usfs_fia.plot` AS p
          ON c.plot_sequence_number = p.plot_sequence_number
      JOIN
        `bigquery-public-data.usfs_fia.population` AS pop
          ON c.plot_sequence_number = pop.plot_sequence_number
      WHERE
        p.measurement_year IN (2015, 2016, 2017)
        AND c.condition_status_code = 1
        AND pop.evaluation_type = 'EXPCURR'
        AND c.proportion_basis = 'MACR'
        AND pop.adjustment_factor_for_the_macroplot > 0
        AND pop.expansion_factor IS NOT NULL
        AND c.condition_proportion_unadjusted IS NOT NULL
      GROUP BY
        p.measurement_year,
        c.state_code
    ) AS avg_sizes
    GROUP BY
      Type,
      Year
  ) AS max_sizes
    ON result.Type = max_sizes.Type
    AND result.Year = max_sizes.Year
    AND result.Average_Size = max_sizes.Max_Average_Size
) AS final_result
ORDER BY
  Type,
  Year;