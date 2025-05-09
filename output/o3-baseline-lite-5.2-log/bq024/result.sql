-- Top 10 evaluation groups (report year 2012) ranked by the subplot acres of
-- their single largest‑subplot‑acre condition.  Acres are calculated as
-- expansion_factor × proportion_unadjusted.
WITH cond_pop AS (
  SELECT
    p.evaluation_group,
    p.evaluation_type,
    c.condition_status_code,
    p.evaluation_description,
    p.state_code,
    -- proportions held on the condition record
    c.macroplot_proportion_unadjusted,
    c.subplot_proportion_unadjusted,
    -- expansion factor held on the population view
    p.expansion_factor,
    -- acre calculations
    p.expansion_factor * c.macroplot_proportion_unadjusted AS macroplot_acres,
    p.expansion_factor * c.subplot_proportion_unadjusted  AS subplot_acres
  FROM `bigquery-public-data.usfs_fia.population` AS p
  JOIN `bigquery-public-data.usfs_fia.condition`  AS c
    ON  p.plot_sequence_number = c.plot_sequence_number
    AND p.inventory_year      = c.inventory_year
    AND p.state_code          = c.state_code
  WHERE c.inventory_year = 2012                  -- limit to 2012 conditions
),

ranked AS (
  SELECT
    *,
    ROW_NUMBER() OVER (
      PARTITION BY evaluation_group
      ORDER BY subplot_acres DESC, macroplot_acres DESC
    ) AS rn
  FROM cond_pop
)

SELECT
  evaluation_group,
  evaluation_type,
  condition_status_code,
  evaluation_description,
  state_code,
  ROUND(macroplot_acres, 4) AS macroplot_acres,
  ROUND(subplot_acres , 4) AS subplot_acres
FROM ranked
WHERE rn = 1                     -- keep only the largest‑subplot condition per group
ORDER BY subplot_acres DESC
LIMIT 10;