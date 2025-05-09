/*  Top-10 Evaluation Groups (year = 2012) by the subplot acres of the
    single largest-acre “condition” (approximated by the plot that
    carries that condition).                                                */

WITH eval_plot AS (         -- 1. plots that belong to 2012 evaluations
    SELECT
        "evaluation_group",
        "evaluation_type",
        "evaluation_description",
        "state_code",
        "plot_sequence_number",
        "macroplot_acres",
        "subplot_acres"
    FROM USFS_FIA.USFS_FIA."ESTIMATED_FORESTLAND_ACRES"
    WHERE "inventory_year" = 2012
),

ranked AS (                 -- 2. keep only the single plot (condition)
    SELECT
        ep.*,
        ROW_NUMBER() OVER (
            PARTITION BY ep."evaluation_group", ep."evaluation_type"
            ORDER BY ep."subplot_acres" DESC NULLS LAST
        ) AS rn
    FROM eval_plot ep
),

top_plot AS (               -- 3. one record per evaluation_group
    SELECT *
    FROM ranked
    WHERE rn = 1
),

/* 4. attach a condition_status_code; there can be several condition
      rows for the same plot, so pick an arbitrary representative (MAX). */
top_plot_with_condition AS (
    SELECT
        tp."evaluation_group",
        tp."evaluation_type",
        MAX(c."condition_status_code")       AS "condition_status_code",
        tp."evaluation_description",
        tp."state_code",
        tp."macroplot_acres",
        tp."subplot_acres"
    FROM top_plot tp
    LEFT JOIN USFS_FIA.USFS_FIA."CONDITION"  c
           ON  c."plot_sequence_number" = tp."plot_sequence_number"
           AND c."inventory_year"      = 2012
    GROUP BY
        tp."evaluation_group",
        tp."evaluation_type",
        tp."evaluation_description",
        tp."state_code",
        tp."macroplot_acres",
        tp."subplot_acres"
)

/* 5. top-10 evaluation groups with the largest subplot acres */
SELECT
    "evaluation_group",
    "evaluation_type",
    "condition_status_code",
    "evaluation_description",
    "state_code",
    "macroplot_acres",
    "subplot_acres"
FROM top_plot_with_condition
ORDER BY "subplot_acres" DESC NULLS LAST
LIMIT 10;