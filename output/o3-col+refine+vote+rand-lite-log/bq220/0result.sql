/*  Largest average SUBPLOT vs. MACROPLOT size, by year (2015-2017)
    ‑ population.evaluation_type  = 'EXPCURR'
    ‑ condition.condition_status_code = 1                                     */

WITH sub_avgs AS (          -- average SUBPLOT size by state & year
  SELECT
      c.inventory_year  AS yr,
      c.state_code_name AS state,
      AVG(
        CASE
          WHEN c.proportion_basis = 'SUBP'
               AND p.adjustment_factor_for_the_subplot > 0
          THEN p.expansion_factor *
               c.condition_proportion_unadjusted *
               p.adjustment_factor_for_the_subplot
          ELSE 0
        END
      ) AS avg_size
  FROM `bigquery-public-data.usfs_fia.population`  AS p
  JOIN `bigquery-public-data.usfs_fia.condition`   AS c
    ON p.plot_sequence_number = c.plot_sequence_number
  WHERE p.evaluation_type       = 'EXPCURR'
    AND c.condition_status_code = 1
    AND c.inventory_year BETWEEN 2015 AND 2017
  GROUP BY yr, state
),
sub_best AS (               -- pick biggest-average SUBPLOT state each year
  SELECT
    'Subplot' AS plot_kind,
    yr,
    state     AS state_with_largest_average_size,
    avg_size
  FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY yr ORDER BY avg_size DESC) AS rn
    FROM sub_avgs
  )
  WHERE rn = 1
),

mac_avgs AS (               -- average MACROPLOT size by state & year
  SELECT
      c.inventory_year  AS yr,
      c.state_code_name AS state,
      AVG(
        CASE
          WHEN c.proportion_basis = 'MACR'
               AND p.adjustment_factor_for_the_macroplot > 0
          THEN p.expansion_factor *
               c.condition_proportion_unadjusted *
               p.adjustment_factor_for_the_macroplot
          ELSE 0
        END
      ) AS avg_size
  FROM `bigquery-public-data.usfs_fia.population`  AS p
  JOIN `bigquery-public-data.usfs_fia.condition`   AS c
    ON p.plot_sequence_number = c.plot_sequence_number
  WHERE p.evaluation_type       = 'EXPCURR'
    AND c.condition_status_code = 1
    AND c.inventory_year BETWEEN 2015 AND 2017
  GROUP BY yr, state
),
mac_best AS (               -- pick biggest-average MACROPLOT state each year
  SELECT
    'Macroplot' AS plot_kind,
    yr,
    state     AS state_with_largest_average_size,
    avg_size
  FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY yr ORDER BY avg_size DESC) AS rn
    FROM mac_avgs
  )
  WHERE rn = 1
)

SELECT
  plot_kind,
  yr   AS year,
  state_with_largest_average_size,
  ROUND(avg_size, 2) AS average_size
FROM sub_best

UNION ALL

SELECT
  plot_kind,
  yr,
  state_with_largest_average_size,
  ROUND(avg_size, 2)
FROM mac_best

ORDER BY year, plot_kind;