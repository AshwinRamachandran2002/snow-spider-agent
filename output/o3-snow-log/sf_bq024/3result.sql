WITH base AS (
    SELECT
        efa."evaluation_group",
        efa."evaluation_type",
        c."condition_status_code",
        efa."evaluation_description",
        efa."state_code",
        efa."macroplot_acres",
        efa."subplot_acres"
    FROM USFS_FIA.USFS_FIA.ESTIMATED_FORESTLAND_ACRES efa
    LEFT JOIN USFS_FIA.USFS_FIA.CONDITION c
        ON efa."plot_sequence_number" = c."plot_sequence_number"
       AND efa."inventory_year"     = c."inventory_year"
    WHERE efa."inventory_year" = 2012
),
ranked AS (
    SELECT
        base.*,
        ROW_NUMBER() OVER (
            PARTITION BY base."evaluation_group"
            ORDER BY base."subplot_acres" DESC NULLS LAST
        ) AS rn
    FROM base
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