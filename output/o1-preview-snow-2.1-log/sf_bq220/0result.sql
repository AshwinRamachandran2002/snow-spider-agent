SELECT
    ranked."plot_type",
    ranked."year",
    ranked."state",
    ROUND(ranked."average_size", 4) AS "average_size"
FROM (
    SELECT
        "plot_type",
        "year",
        "state",
        "average_size",
        ROW_NUMBER() OVER (
            PARTITION BY "plot_type", "year"
            ORDER BY "average_size" DESC NULLS LAST
        ) AS "rn"
    FROM (
        SELECT
            sub."plot_type",
            sub."plot_inventory_year" AS "year",
            sub."plot_state_code_name" AS "state",
            AVG(sub.area) AS "average_size"
        FROM (
            SELECT
                P."plot_sequence_number",
                P."plot_inventory_year",
                P."plot_state_code_name",
                CASE
                    WHEN C."proportion_basis" = 'SUBP' THEN 'subplot'
                    WHEN C."proportion_basis" = 'MACR' THEN 'macroplot'
                    ELSE 'unknown'
                END AS "plot_type",
                CASE
                    WHEN C."proportion_basis" = 'SUBP' AND COALESCE(PS."adjustment_factor_for_the_subplot", 0) > 0
                        THEN PS."expansion_factor" * C."condition_proportion_unadjusted" * PS."adjustment_factor_for_the_subplot"
                    WHEN C."proportion_basis" = 'MACR' AND COALESCE(PS."adjustment_factor_for_the_macroplot", 0) > 0
                        THEN PS."expansion_factor" * C."condition_proportion_unadjusted" * PS."adjustment_factor_for_the_macroplot"
                    ELSE NULL
                END AS area
            FROM "USFS_FIA"."USFS_FIA"."PLOT" P
            JOIN "USFS_FIA"."USFS_FIA"."CONDITION" C
                ON P."plot_sequence_number" = C."plot_sequence_number"
            JOIN "USFS_FIA"."USFS_FIA"."POPULATION_STRATUM_ASSIGN" PSA
                ON P."plot_sequence_number" = PSA."plot_sequence_number"
            JOIN "USFS_FIA"."USFS_FIA"."POPULATION_STRATUM" PS
                ON PSA."stratum_sequence_number" = PS."stratum_sequence_number"
            JOIN "USFS_FIA"."USFS_FIA"."POPULATION_ESTIMATION_UNIT" PEU
                ON PS."estimation_unit_sequence_number" = PEU."estimation_unit_sequence_number"
            JOIN "USFS_FIA"."USFS_FIA"."POPULATION_EVALUATION" PE
                ON PEU."evaluation_sequence_number" = PE."evaluation_sequence_number"
            JOIN "USFS_FIA"."USFS_FIA"."POPULATION_EVALUATION_TYPE" PET
                ON PE."evaluation_sequence_number" = PET."evaluation_sequence_number"
            WHERE
                P."plot_inventory_year" IN (2015, 2016, 2017)
                AND PET."evaluation_type" = 'EXPCURR'
                AND C."condition_status_code" = 1  -- Accessible forest land
        ) AS sub
        WHERE sub.area IS NOT NULL
        GROUP BY
            sub."plot_type",
            sub."plot_inventory_year",
            sub."plot_state_code_name"
    ) AS avg_sizes
) AS ranked
WHERE ranked."rn" = 1
ORDER BY "plot_type", "year";