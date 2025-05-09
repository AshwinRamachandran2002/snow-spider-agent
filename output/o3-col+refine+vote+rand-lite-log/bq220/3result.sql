--  Largest average subplot and macroplot sizes (2015-2017)
WITH pop_curr AS (          -- one EXPCURR row per plot / year
  SELECT *
  FROM (
    SELECT p.*,
           ROW_NUMBER() OVER(PARTITION BY p.plot_sequence_number,
                                         p.inventory_year
                              ORDER BY p.stratum_assign_sequence_number) AS rn
    FROM `bigquery-public-data.usfs_fia.population` AS p
    WHERE p.evaluation_type = 'EXPCURR'
  )
  WHERE rn = 1
),
cond AS (                   -- keep only accessible conditions
  SELECT c.plot_sequence_number,
         c.inventory_year,
         c.state_code,
         c.proportion_basis,
         c.condition_proportion_unadjusted
  FROM `bigquery-public-data.usfs_fia.condition` AS c
  WHERE c.condition_status_code = 1
        AND c.inventory_year IN (2015, 2016, 2017)
),
subplot AS (
  SELECT c.state_code,
         c.inventory_year,
         AVG( pop.expansion_factor
            * c.condition_proportion_unadjusted
            * pop.adjustment_factor_for_the_subplot )          AS avg_size
  FROM cond  AS c
  JOIN pop_curr AS pop
    ON pop.plot_sequence_number = c.plot_sequence_number
   AND pop.inventory_year       = c.inventory_year
  WHERE c.proportion_basis                 = 'SUBP'
    AND pop.adjustment_factor_for_the_subplot > 0
  GROUP BY c.state_code, c.inventory_year
),
macroplot AS (
  SELECT c.state_code,
         c.inventory_year,
         AVG( pop.expansion_factor
            * c.condition_proportion_unadjusted
            * pop.adjustment_factor_for_the_macroplot )        AS avg_size
  FROM cond  AS c
  JOIN pop_curr AS pop
    ON pop.plot_sequence_number = c.plot_sequence_number
   AND pop.inventory_year       = c.inventory_year
  WHERE c.proportion_basis                   = 'MACR'
    AND pop.adjustment_factor_for_the_macroplot > 0
  GROUP BY c.state_code, c.inventory_year
),
max_subplot AS (            -- state with the largest average subplot size
  SELECT 'SUBPLOT'  AS plot_type,
         inventory_year AS year,
         state_code    AS state,
         avg_size
  FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY inventory_year
                                 ORDER BY avg_size DESC) AS rn
    FROM subplot
  )
  WHERE rn = 1
),
max_macroplot AS (          -- state with the largest average macroplot size
  SELECT 'MACROPLOT' AS plot_type,
         inventory_year AS year,
         state_code    AS state,
         avg_size
  FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY inventory_year
                                 ORDER BY avg_size DESC) AS rn
    FROM macroplot
  )
  WHERE rn = 1
)
SELECT *
FROM max_subplot
UNION ALL
SELECT *
FROM max_macroplot
ORDER BY plot_type, year;