WITH Subplot_Averages AS (
    SELECT
        'subplot' AS plot_type,
        c."inventory_year" AS year,
        c."state_code_name" AS state,
        ROUND(AVG(ps."expansion_factor" * c."condition_proportion_unadjusted" * ps."adjustment_factor_for_the_subplot"), 4) AS average_size
    FROM "USFS_FIA"."USFS_FIA"."CONDITION" c
    JOIN "USFS_FIA"."USFS_FIA"."POPULATION_STRATUM_ASSIGN" psa
        ON c."plot_sequence_number" = psa."plot_sequence_number"
    JOIN "USFS_FIA"."USFS_FIA"."POPULATION_STRATUM" ps
        ON psa."stratum_sequence_number" = ps."stratum_sequence_number"
    JOIN "USFS_FIA"."USFS_FIA"."POPULATION_ESTIMATION_UNIT" peu
        ON ps."estimation_unit_sequence_number" = peu."estimation_unit_sequence_number"
    JOIN "USFS_FIA"."USFS_FIA"."POPULATION_EVALUATION" pe
        ON peu."evaluation_sequence_number" = pe."evaluation_sequence_number"
    JOIN "USFS_FIA"."USFS_FIA"."POPULATION_EVALUATION_TYPE" pet
        ON pe."evaluation_sequence_number" = pet."evaluation_sequence_number"
    WHERE
        c."proportion_basis" = 'SUBP'
        AND c."inventory_year" IN (2015, 2016, 2017)
        AND c."condition_status_code" = 1
        AND pet."evaluation_type" = 'EXPCURR'
        AND ps."adjustment_factor_for_the_subplot" > 0
    GROUP BY c."inventory_year", c."state_code_name"
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY c."inventory_year" 
        ORDER BY average_size DESC NULLS LAST
    ) = 1
),
Macroplot_Averages AS (
    SELECT
        'macroplot' AS plot_type,
        c."inventory_year" AS year,
        c."state_code_name" AS state,
        ROUND(AVG(ps."expansion_factor" * c."condition_proportion_unadjusted" * ps."adjustment_factor_for_the_macroplot"), 4) AS average_size
    FROM "USFS_FIA"."USFS_FIA"."CONDITION" c
    JOIN "USFS_FIA"."USFS_FIA"."POPULATION_STRATUM_ASSIGN" psa
        ON c."plot_sequence_number" = psa."plot_sequence_number"
    JOIN "USFS_FIA"."USFS_FIA"."POPULATION_STRATUM" ps
        ON psa."stratum_sequence_number" = ps."stratum_sequence_number"
    JOIN "USFS_FIA"."USFS_FIA"."POPULATION_ESTIMATION_UNIT" peu
        ON ps."estimation_unit_sequence_number" = peu."estimation_unit_sequence_number"
    JOIN "USFS_FIA"."USFS_FIA"."POPULATION_EVALUATION" pe
        ON peu."evaluation_sequence_number" = pe."evaluation_sequence_number"
    JOIN "USFS_FIA"."USFS_FIA"."POPULATION_EVALUATION_TYPE" pet
        ON pe."evaluation_sequence_number" = pet."evaluation_sequence_number"
    WHERE
        c."proportion_basis" = 'MACR'
        AND c."inventory_year" IN (2015, 2016, 2017)
        AND c."condition_status_code" = 1
        AND pet."evaluation_type" = 'EXPCURR'
        AND ps."adjustment_factor_for_the_macroplot" > 0
    GROUP BY c."inventory_year", c."state_code_name"
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY c."inventory_year" 
        ORDER BY average_size DESC NULLS LAST
    ) = 1
)
SELECT *
FROM (
    SELECT * FROM Subplot_Averages
    UNION ALL
    SELECT * FROM Macroplot_Averages
)
ORDER BY plot_type, year;