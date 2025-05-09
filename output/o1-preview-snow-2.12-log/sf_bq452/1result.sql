WITH population_counts AS (
    SELECT
        p."Population",
        COUNT(*) AS "Sample_Count"
    FROM
        "_1000_GENOMES"."_1000_GENOMES"."PEDIGREE" p
    WHERE
        p."Population" IS NOT NULL
    GROUP BY
        p."Population"
    ORDER BY
        "Sample_Count" DESC
    LIMIT 2
),
selected_samples AS (
    SELECT
        p."Individual_ID",
        p."Population"
    FROM
        "_1000_GENOMES"."_1000_GENOMES"."PEDIGREE" p
    JOIN
        population_counts pc
        ON p."Population" = pc."Population"
),
variant_genotypes AS (
    SELECT
        v."start",
        v."end",
        c.value:"call_set_name"::STRING AS "Sample_ID",
        p."Population",
        COALESCE(c.value:"genotype"[0]::INTEGER, 0) AS "allele1",
        COALESCE(c.value:"genotype"[1]::INTEGER, 0) AS "allele2"
    FROM
        "_1000_GENOMES"."_1000_GENOMES"."VARIANTS" v
        CROSS JOIN LATERAL FLATTEN(input => v."call") c
        JOIN selected_samples p ON c.value:"call_set_name"::STRING = p."Individual_ID"
    WHERE
        v."reference_name" = '12'
        AND c.value:"genotype" IS NOT NULL
),
allele_counts AS (
    SELECT
        "start",
        "end",
        "Population",
        SUM("allele1" + "allele2") AS "alt_allele_count",
        COUNT(*) * 2 - SUM("allele1" + "allele2") AS "ref_allele_count"
    FROM
        variant_genotypes
    GROUP BY
        "start",
        "end",
        "Population"
),
chi_squared_inputs AS (
    SELECT
        ac."start",
        ac."end",
        MAX(CASE WHEN ac."Population" = (SELECT "Population" FROM population_counts LIMIT 1 OFFSET 0) THEN ac."alt_allele_count" ELSE 0 END) AS "group1_alt",
        MAX(CASE WHEN ac."Population" = (SELECT "Population" FROM population_counts LIMIT 1 OFFSET 0) THEN ac."ref_allele_count" ELSE 0 END) AS "group1_ref",
        MAX(CASE WHEN ac."Population" = (SELECT "Population" FROM population_counts LIMIT 1 OFFSET 1) THEN ac."alt_allele_count" ELSE 0 END) AS "group2_alt",
        MAX(CASE WHEN ac."Population" = (SELECT "Population" FROM population_counts LIMIT 1 OFFSET 1) THEN ac."ref_allele_count" ELSE 0 END) AS "group2_ref"
    FROM
        allele_counts ac
    GROUP BY
        ac."start",
        ac."end"
),
chi_squared_totals AS (
    SELECT
        ci."start",
        ci."end",
        ci."group1_alt",
        ci."group1_ref",
        ci."group2_alt",
        ci."group2_ref",
        ci."group1_alt" + ci."group2_alt" AS "total_alt",
        ci."group1_ref" + ci."group2_ref" AS "total_ref",
        ci."group1_alt" + ci."group1_ref" + ci."group2_alt" + ci."group2_ref" AS "total"
    FROM
        chi_squared_inputs ci
),
chi_squared_scores AS (
    SELECT
        ct."start",
        ct."end",
        ROUND((ct."total_alt" * (ct."group1_alt" + ct."group1_ref") / NULLIF(ct."total", 0)), 4) AS "expected_group1_alt",
        ROUND((ct."total_alt" * (ct."group2_alt" + ct."group2_ref") / NULLIF(ct."total", 0)), 4) AS "expected_group2_alt",
        ROUND(
            (
                POWER(
                    ABS(ct."group1_alt" * ct."group2_ref" - ct."group2_alt" * ct."group1_ref") - 0.5 * ct."total",
                    2
                ) * ct."total"
            ) /
            NULLIF(
                (ct."group1_alt" + ct."group2_alt")
                * (ct."group1_ref" + ct."group2_ref")
                * (ct."group1_alt" + ct."group1_ref")
                * (ct."group2_alt" + ct."group2_ref"),
                0
            ), 4
        ) AS "chi_squared_score"
    FROM
        chi_squared_totals ct
)
SELECT
    "start",
    "end",
    "chi_squared_score"
FROM
    chi_squared_scores
WHERE
    "expected_group1_alt" >= 5
    AND "expected_group2_alt" >= 5
    AND "chi_squared_score" >= 29.7168
ORDER BY
    "chi_squared_score" DESC NULLS LAST
LIMIT 100;