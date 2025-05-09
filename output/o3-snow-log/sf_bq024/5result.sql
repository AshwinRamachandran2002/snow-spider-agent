WITH per_group AS (
    SELECT
        f."evaluation_group"        AS evaluation_group,
        f."evaluation_type"         AS evaluation_type,
        c."condition_status_code"   AS condition_status_code,
        f."evaluation_description"  AS evaluation_description,
        f."state_code"              AS state_code,
        f."macroplot_acres"         AS macroplot_acres,
        f."subplot_acres"           AS subplot_acres,
        ROW_NUMBER() OVER (
            PARTITION BY f."evaluation_group"
            ORDER BY f."subplot_acres" DESC NULLS LAST
        ) AS rn
    FROM USFS_FIA.USFS_FIA."ESTIMATED_FORESTLAND_ACRES"  f
    LEFT JOIN USFS_FIA.USFS_FIA."CONDITION"              c
           ON c."plot_sequence_number" = f."plot_sequence_number"
          AND c."inventory_year"      = f."inventory_year"
    WHERE f."inventory_year" = 2012
)

SELECT
    evaluation_group,
    evaluation_type,
    condition_status_code,
    evaluation_description,
    state_code,
    macroplot_acres,
    subplot_acres
FROM per_group
WHERE rn = 1
ORDER BY subplot_acres DESC NULLS LAST
LIMIT 10;