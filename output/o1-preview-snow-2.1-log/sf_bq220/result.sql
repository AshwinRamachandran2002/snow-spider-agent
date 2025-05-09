WITH subplot_data AS (
    SELECT
        'subplot' AS "plot_type",
        qc."inventory_year" AS "year",
        sname."state_code_name" AS "state",
        ROUND(AVG(qp."expansion_factor" * qc."condition_proportion_unadjusted" * qp."adjustment_factor_for_the_subplot"), 4) AS "average_size"
    FROM
        "USFS_FIA"."USFS_FIA"."CONDITION" qc
    JOIN
        "USFS_FIA"."USFS_FIA"."POPULATION" qp
            ON qc."plot_sequence_number" = qp."plot_sequence_number"
    JOIN
        "USFS_FIA"."USFS_FIA"."POPULATION_EVALUATION_TYPE" et
            ON qp."evaluation_sequence_number" = et."evaluation_sequence_number"
    JOIN
        (SELECT DISTINCT "state_code", "state_code_name" FROM "USFS_FIA"."USFS_FIA"."CONDITION") sname
            ON qc."state_code" = sname."state_code"
    WHERE
        qc."inventory_year" IN (2015, 2016, 2017)
        AND qc."condition_status_code_name" = 'Accessible forest land'
        AND qc."proportion_basis" = 'SUBP'
        AND qc."condition_proportion_unadjusted" > 0
        AND qp."adjustment_factor_for_the_subplot" > 0
        AND et."evaluation_type" = 'EXPCURR'
    GROUP BY
        qc."inventory_year", sname."state_code_name"
),
subplot_max AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY "plot_type", "year" ORDER BY "average_size" DESC NULLS LAST) AS rn
    FROM subplot_data
),
macroplot_data AS (
    SELECT
        'macroplot' AS "plot_type",
        qc."inventory_year" AS "year",
        sname."state_code_name" AS "state",
        ROUND(AVG(qp."expansion_factor" * qc."condition_proportion_unadjusted" * qp."adjustment_factor_for_the_macroplot"), 4) AS "average_size"
    FROM
        "USFS_FIA"."USFS_FIA"."CONDITION" qc
    JOIN
        "USFS_FIA"."USFS_FIA"."POPULATION" qp
            ON qc."plot_sequence_number" = qp."plot_sequence_number"
    JOIN
        "USFS_FIA"."USFS_FIA"."POPULATION_EVALUATION_TYPE" et
            ON qp."evaluation_sequence_number" = et."evaluation_sequence_number"
    JOIN
        (SELECT DISTINCT "state_code", "state_code_name" FROM "USFS_FIA"."USFS_FIA"."CONDITION") sname
            ON qc."state_code" = sname."state_code"
    WHERE
        qc."inventory_year" IN (2015, 2016, 2017)
        AND qc."condition_status_code_name" = 'Accessible forest land'
        AND qc."proportion_basis" = 'MACR'
        AND qc."condition_proportion_unadjusted" > 0
        AND qp."adjustment_factor_for_the_macroplot" > 0
        AND et."evaluation_type" = 'EXPCURR'
    GROUP BY
        qc."inventory_year", sname."state_code_name"
),
macroplot_max AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY "plot_type", "year" ORDER BY "average_size" DESC NULLS LAST) AS rn
    FROM macroplot_data
)
SELECT "plot_type", "year", "state", "average_size"
FROM (
    SELECT "plot_type", "year", "state", "average_size"
    FROM subplot_max
    WHERE rn = 1
    UNION ALL
    SELECT "plot_type", "year", "state", "average_size"
    FROM macroplot_max
    WHERE rn = 1
)
ORDER BY "plot_type", "year";