/*  Top-10 evaluation groups (year 2012) by the subplot acres of the
    single condition (plot) with the largest subplot acres in each group  */

WITH efa_2012 AS (   -- 2012 rows from Estimated Forestland Acres
    SELECT
        "plot_sequence_number",
        "evaluation_group",
        "evaluation_type",
        "evaluation_description",
        "state_code",
        "macroplot_acres",
        "subplot_acres",
        ROW_NUMBER() OVER (
            PARTITION BY "evaluation_group"
            ORDER BY "subplot_acres" DESC NULLS LAST
        ) AS rn          -- rank within each evaluation group
    FROM USFS_FIA.USFS_FIA."ESTIMATED_FORESTLAND_ACRES"
    WHERE "inventory_year" = 2012
),
top_plot_per_group AS (     -- keep the plot with the largest subplot acres
    SELECT *
    FROM efa_2012
    WHERE rn = 1
),
cond_2012 AS (      -- 2012 condition status for every plot
    SELECT
        "plot_sequence_number",
        "condition_status_code",
        ROW_NUMBER() OVER (          -- pick the first condition record
            PARTITION BY "plot_sequence_number"
            ORDER BY "condition_class_number"  -- usually 1 first
        ) AS rn
    FROM USFS_FIA.USFS_FIA."CONDITION"
    WHERE "inventory_year" = 2012
)
SELECT
    t."evaluation_group",
    t."evaluation_type",
    c."condition_status_code",
    t."evaluation_description",
    t."state_code",
    t."macroplot_acres",
    t."subplot_acres"
FROM top_plot_per_group AS t
LEFT JOIN cond_2012      c
       ON c."plot_sequence_number" = t."plot_sequence_number"
      AND c.rn = 1
ORDER BY t."subplot_acres" DESC NULLS LAST
LIMIT 10;