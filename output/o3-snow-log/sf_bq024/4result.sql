/*  Top-10 evaluation groups (year 2012) by the single condition
    that has the largest “subplot_acres” within each group          */

WITH joined AS (
    SELECT
        efa."evaluation_group",
        efa."evaluation_type",
        efa."evaluation_description",
        efa."state_code",
        efa."macroplot_acres",
        efa."subplot_acres",
        c."condition_status_code"
    FROM USFS_FIA.USFS_FIA."ESTIMATED_FORESTLAND_ACRES"  efa
    LEFT JOIN USFS_FIA.USFS_FIA."CONDITION"              c
           ON efa."plot_sequence_number" = c."plot_sequence_number"
          AND efa."inventory_year"      = c."inventory_year"
    WHERE efa."inventory_year" = 2012
), ranked AS (
    SELECT
        j.*,
        ROW_NUMBER() OVER (PARTITION BY j."evaluation_group"
                           ORDER BY j."subplot_acres" DESC NULLS LAST) AS rn
    FROM joined j
)
SELECT
    "evaluation_group",
    "evaluation_type",
    "condition_status_code",
    "evaluation_description",
    "state_code",
    "macroplot_acres",
    "subplot_acres"
FROM ranked
WHERE rn = 1
ORDER BY "subplot_acres" DESC NULLS LAST
LIMIT 10;