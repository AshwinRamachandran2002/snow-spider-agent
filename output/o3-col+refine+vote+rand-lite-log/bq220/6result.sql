-- States with the largest average subplot-size and macroplot-size
-- for each year 2015-2017 (evaluation_type = 'EXPCURR', condition_status_code = 1)

WITH base AS (
  SELECT
    p.inventory_year   AS year,
    p.state_code,
    c.proportion_basis,
    p.expansion_factor,
    c.condition_proportion_unadjusted,
    p.adjustment_factor_for_the_subplot   AS adj_subp,
    p.adjustment_factor_for_the_macroplot AS adj_macr
  FROM `bigquery-public-data.usfs_fia.population`  AS p
  JOIN `bigquery-public-data.usfs_fia.condition`   AS c
    ON  c.plot_sequence_number = p.plot_sequence_number
    AND c.inventory_year      = p.inventory_year
  WHERE p.evaluation_type      = 'EXPCURR'
    AND c.condition_status_code = 1
    AND p.inventory_year BETWEEN 2015 AND 2017
    AND c.proportion_basis IN ('SUBP','MACR')
),

plot_sizes AS (
  SELECT
    year,
    state_code,
    proportion_basis,
    CASE
      WHEN proportion_basis = 'SUBP' AND adj_subp  > 0
           THEN expansion_factor * condition_proportion_unadjusted * adj_subp
      WHEN proportion_basis = 'MACR' AND adj_macr > 0
           THEN expansion_factor * condition_proportion_unadjusted * adj_macr
    END AS plot_size
  FROM base
  WHERE (proportion_basis = 'SUBP' AND adj_subp  > 0)
     OR (proportion_basis = 'MACR' AND adj_macr > 0)
),

avg_by_state AS (
  SELECT
    year,
    state_code,
    proportion_basis AS plot_type,
    AVG(plot_size)  AS avg_size
  FROM plot_sizes
  GROUP BY year, state_code, plot_type
),

top_state_per_year AS (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY year, plot_type
                       ORDER BY avg_size DESC) AS rn
  FROM avg_by_state
)

SELECT
  CASE WHEN plot_type = 'SUBP' THEN 'Subplot'
       ELSE 'Macroplot' END       AS plot_type,
  year,
  state_code                     AS state,
  ROUND(avg_size, 4)             AS average_size
FROM top_state_per_year
WHERE rn = 1
ORDER BY year, plot_type;