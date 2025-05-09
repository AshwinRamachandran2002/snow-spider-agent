WITH joined AS (
    SELECT 
        ef."evaluation_group",
        ef."evaluation_type",
        c."condition_status_code",
        ef."evaluation_description",
        ef."state_code",
        ef."macroplot_acres",
        ef."subplot_acres"
    FROM USFS_FIA.USFS_FIA."ESTIMATED_FORESTLAND_ACRES"  ef
    JOIN USFS_FIA.USFS_FIA."CONDITION"                   c
      ON ef."plot_sequence_number" = c."plot_sequence_number"
     AND ef."inventory_year"      = c."inventory_year"
    WHERE ef."inventory_year" = 2012
),
ranked AS (
    SELECT 
        j.*,
        ROW_NUMBER() OVER (
            PARTITION BY j."evaluation_group" 
            ORDER BY j."subplot_acres" DESC NULLS LAST
        ) AS rn
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