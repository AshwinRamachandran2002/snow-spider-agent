WITH size_data AS (
    SELECT
        CASE 
            WHEN c."proportion_basis" = 'SUBP' THEN 'subplot'
            WHEN c."proportion_basis" = 'MACR' THEN 'macroplot'
        END AS "Type",
        c."inventory_year" AS "Year",
        p."plot_state_code_name" AS "State",
        (ps."expansion_factor" * c."condition_proportion_unadjusted" * 
            CASE 
                WHEN c."proportion_basis" = 'SUBP' THEN ps."adjustment_factor_for_the_subplot"
                WHEN c."proportion_basis" = 'MACR' THEN ps."adjustment_factor_for_the_macroplot"
            END
        ) AS "Size"
    FROM "USFS_FIA"."USFS_FIA"."CONDITION" c
    JOIN "USFS_FIA"."USFS_FIA"."PLOT" p
        ON c."plot_sequence_number" = p."plot_sequence_number"
    JOIN "USFS_FIA"."USFS_FIA"."POPULATION_STRATUM_ASSIGN" psa
        ON c."plot_sequence_number" = psa."plot_sequence_number"
    JOIN "USFS_FIA"."USFS_FIA"."POPULATION_STRATUM" ps
        ON psa."stratum_sequence_number" = ps."stratum_sequence_number"
    JOIN "USFS_FIA"."USFS_FIA"."POPULATION_EVALUATION" pe
        ON ps."evaluation_identifier" = pe."evaluation_identifier"
    JOIN "USFS_FIA"."USFS_FIA"."POPULATION_EVALUATION_TYPE" pet
        ON pe."evaluation_sequence_number" = pet."evaluation_sequence_number"
    WHERE c."condition_status_code" = 1
        AND c."inventory_year" IN (2015, 2016, 2017)
        AND pet."evaluation_type" = 'EXPCURR'
        AND (
            (c."proportion_basis" = 'SUBP' AND ps."adjustment_factor_for_the_subplot" > 0)
            OR
            (c."proportion_basis" = 'MACR' AND ps."adjustment_factor_for_the_macroplot" > 0)
        )
        AND ps."expansion_factor" IS NOT NULL
        AND c."condition_proportion_unadjusted" IS NOT NULL
),
average_sizes AS (
    SELECT
        "Type",
        "Year",
        "State",
        AVG("Size") AS "Average_Size"
    FROM size_data
    GROUP BY "Type", "Year", "State"
),
ranked_states AS (
    SELECT
        "Type",
        "Year",
        "State",
        "Average_Size",
        ROW_NUMBER() OVER (PARTITION BY "Type", "Year" ORDER BY "Average_Size" DESC NULLS LAST) AS "Rank"
    FROM average_sizes
)
SELECT
    "Type",
    "Year",
    "State",
    ROUND("Average_Size", 4) AS "Average_Size"
FROM ranked_states
WHERE "Rank" = 1
ORDER BY "Type", "Year";