-- top 10 evaluation groups (year 2012) by largest *subplot acres*
WITH cond_2012 AS (
  SELECT
      c.sequence_number                      AS condition_sequence_number,
      c.plot_sequence_number,
      c.condition_class_number,
      c.condition_status_code,
      c.subplot_proportion_unadjusted,
      c.macroplot_proportion_unadjusted,
      c.inventory_year,
      c.state_code
  FROM `bigquery-public-data.usfs_fia.condition` AS c
  WHERE c.inventory_year = 2012          -- focus on 2012
),

cond_pop AS (
  /*  join to population table (has expansion factor & evaluation metadata)  */
  SELECT
      p.evaluation_group,                       -- group id (e.g. 122012 etc.)
      p.evaluation_type,                        -- EXPVOL, EXPCURR, ….
      p.evaluation_description,
      p.state_code,
      c.condition_status_code,
      /*  acres = expansion_factor × proportion × adjustment  */
      COALESCE(c.macroplot_proportion_unadjusted,0)
        * COALESCE(p.adjustment_factor_for_the_macroplot,1)
        * p.expansion_factor                                      AS macroplot_acres,
      COALESCE(c.subplot_proportion_unadjusted,0)
        * COALESCE(p.adjustment_factor_for_the_subplot,1)
        * p.expansion_factor                                      AS subplot_acres
  FROM cond_2012      AS c
  JOIN `bigquery-public-data.usfs_fia.population` AS p
    ON  c.plot_sequence_number = p.plot_sequence_number
    AND p.inventory_year      = 2012             -- same inventory year
),

largest_per_group AS (
  /* pick the condition with largest subplot acres inside each evaluation group */
  SELECT *,
         ROW_NUMBER() OVER (PARTITION BY evaluation_group
                            ORDER BY subplot_acres DESC) AS rn
  FROM cond_pop
)

SELECT
    evaluation_group,
    evaluation_type,
    condition_status_code,
    evaluation_description,
    state_code,
    macroplot_acres,
    subplot_acres
FROM largest_per_group
WHERE rn = 1                      -- keep only the largest condition in each group
ORDER BY subplot_acres DESC       -- top 10 groups by subplot acres
LIMIT 10;