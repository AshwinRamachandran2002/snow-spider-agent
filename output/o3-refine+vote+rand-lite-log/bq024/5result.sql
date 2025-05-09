-- Top‑10 evaluation groups (report year 2012) ranked by the subplot‑acres of the
-- single condition that has the largest subplot‑acres inside each group.
-- Acre conversions follow FIA plot design:
--   macro‑plot  = 1/6  acre  ≈ 0.1666667
--   sub‑plot    = 1/24 acre  ≈ 0.0416667
WITH
/* 1. 2012 population information (one row per plot / evaluation‑type) */
pop12 AS (
  SELECT DISTINCT
         evaluation_group,
         evaluation_type,
         evaluation_description,
         state_code,
         plot_sequence_number
  FROM   `bigquery-public-data.usfs_fia.population`
  WHERE  inventory_year = 2012
),
/* 2. 2012 condition records (needed fields only) */
cond12 AS (
  SELECT
         sequence_number              AS condition_sequence_number,
         plot_sequence_number,
         condition_status_code,
         macroplot_proportion_unadjusted,
         subplot_proportion_unadjusted
  FROM   `bigquery-public-data.usfs_fia.condition`
  WHERE  inventory_year = 2012
),
/* 3. Join population ↔ condition, compute acreage */
joined AS (
  SELECT
         p.evaluation_group,
         p.evaluation_type,
         c.condition_status_code,
         p.evaluation_description,
         p.state_code,
         c.macroplot_proportion_unadjusted * 0.1666667 AS macroplot_acres,
         c.subplot_proportion_unadjusted   * 0.0416667 AS subplot_acres
  FROM   pop12 p
  JOIN   cond12 c
  ON     p.plot_sequence_number = c.plot_sequence_number
),
/* 4. Pick, for every evaluation group, the ONE condition that has
      the largest subplot‑acres */
ranked AS (
  SELECT *,
         ROW_NUMBER() OVER (PARTITION BY evaluation_group
                            ORDER BY subplot_acres DESC) AS rn
  FROM   joined
)
-- 5. Return the top‑10 groups
SELECT
       evaluation_group,
       evaluation_type,
       condition_status_code,
       evaluation_description,
       state_code,
       ROUND(macroplot_acres ,4) AS macroplot_acres,
       ROUND(subplot_acres  ,4) AS subplot_acres
FROM   ranked
WHERE  rn = 1
ORDER  BY subplot_acres DESC
LIMIT  10;