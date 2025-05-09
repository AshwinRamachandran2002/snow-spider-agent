SELECT
    t."Type",
    t."Year",
    t."State",
    t."Average_Size"
FROM (
    SELECT
        sub."Type",
        sub."Year",
        sub."State",
        sub."Average_Size",
        ROW_NUMBER() OVER (
            PARTITION BY sub."Year", sub."Type"
            ORDER BY sub."Average_Size" DESC NULLS LAST
        ) AS rn
    FROM (
        SELECT
            CASE
                WHEN c."proportion_basis" = 'SUBP' AND p."adjustment_factor_for_the_subplot" > 0 THEN 'subplot'
                WHEN c."proportion_basis" = 'MACR' AND p."adjustment_factor_for_the_macroplot" > 0 THEN 'macroplot'
            END AS "Type",
            c."inventory_year" AS "Year",
            c."state_code_name" AS "State",
            ROUND(AVG(
                CASE
                    WHEN c."proportion_basis" = 'SUBP' AND p."adjustment_factor_for_the_subplot" > 0 THEN
                        p."expansion_factor" * c."condition_proportion_unadjusted" * p."adjustment_factor_for_the_subplot"
                    WHEN c."proportion_basis" = 'MACR' AND p."adjustment_factor_for_the_macroplot" > 0 THEN
                        p."expansion_factor" * c."condition_proportion_unadjusted" * p."adjustment_factor_for_the_macroplot"
                END
            ), 4) AS "Average_Size"
        FROM
            USFS_FIA.USFS_FIA.CONDITION c
        JOIN
            USFS_FIA.USFS_FIA.POPULATION p ON c."plot_sequence_number" = p."plot_sequence_number"
        JOIN
            USFS_FIA.USFS_FIA.POPULATION_EVALUATION_TYPE pet ON p."evaluation_sequence_number" = pet."evaluation_sequence_number"
        WHERE
            pet."evaluation_type" = 'EXPCURR'
            AND c."condition_status_code" = 1
            AND c."inventory_year" IN (2015, 2016, 2017)
            AND (
                (c."proportion_basis" = 'SUBP' AND p."adjustment_factor_for_the_subplot" > 0)
                OR (c."proportion_basis" = 'MACR' AND p."adjustment_factor_for_the_macroplot" > 0)
            )
        GROUP BY
            "Type", "Year", "State"
    ) sub
) t
WHERE
    t."Type" IS NOT NULL
    AND t.rn = 1
ORDER BY
    t."Year", t."Type";