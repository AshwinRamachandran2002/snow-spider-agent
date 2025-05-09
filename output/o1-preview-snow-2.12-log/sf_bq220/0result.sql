WITH
-- Step 1: Get relevant plots with their state and year
plots AS (
    SELECT
        p."plot_sequence_number",
        p."plot_state_code_name" AS "State",
        p."plot_inventory_year" AS "Year"
    FROM
        "USFS_FIA"."USFS_FIA"."PLOT" p
    WHERE
        p."plot_inventory_year" IN (2015, 2016, 2017)
),
-- Step 2: Get conditions with condition_status_code=1
conditions AS (
    SELECT
        c."plot_sequence_number",
        c."inventory_year" AS "Year",
        c."condition_proportion_unadjusted" AS "P",
        c."proportion_basis",
        c."condition_status_code"
    FROM
        "USFS_FIA"."USFS_FIA"."CONDITION" c
    WHERE
        c."condition_status_code" = 1
        AND c."inventory_year" IN (2015, 2016, 2017)
),
-- Step 3: Get evaluation_identifiers for evaluation_type='EXPCURR'
evaluation_identifiers AS (
    SELECT DISTINCT
        pe."evaluation_identifier"
    FROM
        "USFS_FIA"."USFS_FIA"."POPULATION_EVALUATION" pe
    JOIN
        "USFS_FIA"."USFS_FIA"."POPULATION_EVALUATION_TYPE" pet
        ON pe."evaluation_sequence_number" = pet."evaluation_sequence_number"
    WHERE
        pet."evaluation_type" = 'EXPCURR'
),
-- Step 4: Get stratum assignments for the plots
stratum_assign AS (
    SELECT
        psa."plot_sequence_number",
        psa."evaluation_identifier",
        psa."stratum_sequence_number"
    FROM
        "USFS_FIA"."USFS_FIA"."POPULATION_STRATUM_ASSIGN" psa
    WHERE
        psa."evaluation_identifier" IN (SELECT "evaluation_identifier" FROM evaluation_identifiers)
),
-- Step 5: Get stratum info
stratum AS (
    SELECT
        ps."stratum_sequence_number",
        ps."expansion_factor" AS "E",
        ps."adjustment_factor_for_the_subplot" AS "A_s",
        ps."adjustment_factor_for_the_macroplot" AS "A_m"
    FROM
        "USFS_FIA"."USFS_FIA"."POPULATION_STRATUM" ps
),
-- Step 6: Join everything together
joined AS (
    SELECT
        c."plot_sequence_number",
        c."Year",
        c."P",
        c."proportion_basis",
        s."E",
        s."A_s",
        s."A_m",
        p."State"
    FROM
        conditions c
    JOIN
        plots p ON c."plot_sequence_number" = p."plot_sequence_number" AND c."Year" = p."Year"
    JOIN
        stratum_assign sa ON c."plot_sequence_number" = sa."plot_sequence_number"
    JOIN
        stratum s ON sa."stratum_sequence_number" = s."stratum_sequence_number"
    WHERE
        s."E" IS NOT NULL
        AND p."State" IS NOT NULL
),
-- Step 7: Compute subplot sizes
subplot_sizes AS (
    SELECT
        'subplot' AS "Type",
        j."Year",
        j."State",
        j."P" * j."E" * j."A_s" AS "Size"
    FROM
        joined j
    WHERE
        j."proportion_basis" = 'SUBP'
        AND j."A_s" > 0
),
-- Step 8: Compute macroplot sizes
macroplot_sizes AS (
    SELECT
        'macroplot' AS "Type",
        j."Year",
        j."State",
        j."P" * j."E" * j."A_m" AS "Size"
    FROM
        joined j
    WHERE
        j."proportion_basis" = 'MACR'
        AND j."A_m" > 0
),
-- Step 9: Union the sizes
all_sizes AS (
    SELECT * FROM subplot_sizes
    UNION ALL
    SELECT * FROM macroplot_sizes
),
-- Step 10: Compute the average sizes
average_sizes AS (
    SELECT
        "Type",
        "Year",
        "State",
        AVG("Size") AS "Average_Size"
    FROM
        all_sizes
    GROUP BY
        "Type",
        "Year",
        "State"
),
-- Step 11: Find the max average size per Type and Year
max_average_sizes AS (
    SELECT
        a."Type",
        a."Year",
        a."State",
        a."Average_Size",
        ROW_NUMBER() OVER (PARTITION BY a."Type", a."Year" ORDER BY a."Average_Size" DESC NULLS LAST) AS rn
    FROM
        average_sizes a
)
-- Step 12: Select the top state for each Type and Year
SELECT
    "Type",
    "Year",
    "State",
    ROUND("Average_Size", 4) AS "Average_Size"
FROM
    max_average_sizes
WHERE
    rn = 1
ORDER BY
    "Type", "Year";