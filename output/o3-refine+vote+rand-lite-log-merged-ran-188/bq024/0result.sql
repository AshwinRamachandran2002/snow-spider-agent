-- Top-10  evaluation-groups (2012) by the largest subplot-acres,
-- keeping only the single biggest-subplot condition inside each group
WITH best_per_group AS (
  SELECT
    p.evaluation_group,
    p.evaluation_type,
    c.condition_status_code,
    p.evaluation_description,
    p.state_code,
    -- acreage calculations
    (p.expansion_factor
       * p.adjustment_factor_for_the_macroplot
       * c.macroplot_proportion_unadjusted) AS macroplot_acres,
    (p.expansion_factor
       * p.adjustment_factor_for_the_subplot
       * c.subplot_proportion_unadjusted)   AS subplot_acres,
    -- rank rows inside each group by subplot-acres
    ROW_NUMBER() OVER (
      PARTITION BY p.evaluation_group
      ORDER BY (p.expansion_factor
                * p.adjustment_factor_for_the_subplot
                * c.subplot_proportion_unadjusted) DESC
    ) AS rn
  FROM `bigquery-public-data.usfs_fia.population` AS p
  JOIN `bigquery-public-data.usfs_fia.condition`  AS c
    ON  p.plot_sequence_number = c.plot_sequence_number
   AND p.inventory_year       = c.inventory_year
  WHERE p.inventory_year = 2012          -- focus on year 2012
)

SELECT
  evaluation_group,
  evaluation_type,
  condition_status_code,
  evaluation_description,
  state_code,
  macroplot_acres,
  subplot_acres
FROM best_per_group
WHERE rn = 1                     -- keep only the largest-subplot condition per group
ORDER BY subplot_acres DESC      -- largest subplot-acres first
LIMIT 10;                        -- top-10 groups