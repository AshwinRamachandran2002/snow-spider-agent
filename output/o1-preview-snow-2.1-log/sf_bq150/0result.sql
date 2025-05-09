WITH
expr_mut AS (
    SELECT
        exp."case_barcode",
        LOG(10, exp."normalized_count") AS "log_expression",
        COALESCE(mut."Variant_Classification", 'No Mutation') AS "Variant_Classification"
    FROM
        "TCGA_HG19_DATA_V0"."TCGA_HG19_DATA_V0"."RNASEQ_GENE_EXPRESSION_UNC_RSEM" AS exp
    LEFT JOIN
        (
            SELECT DISTINCT "case_barcode", "Variant_Classification"
            FROM "TCGA_HG19_DATA_V0"."TCGA_HG19_DATA_V0"."SOMATIC_MUTATION_MC3"
            WHERE "Hugo_Symbol" = 'TP53' AND "project_short_name" = 'TCGA-BRCA'
        ) AS mut
        ON exp."case_barcode" = mut."case_barcode"
    WHERE
        exp."HGNC_gene_symbol" = 'TP53'
        AND exp."normalized_count" > 0
        AND exp."project_short_name" = 'TCGA-BRCA'
),
grand_mean AS (
    SELECT AVG("log_expression") AS "grand_mean" FROM expr_mut
),
group_stats AS (
    SELECT
        "Variant_Classification",
        COUNT(*) AS n_j,
        AVG("log_expression") AS mean_j
    FROM
        expr_mut
    GROUP BY
        "Variant_Classification"
),
ssb AS (
    SELECT SUM(gs.n_j * POWER(gs.mean_j - gm."grand_mean", 2)) AS ssb
    FROM
        group_stats gs, grand_mean gm
),
ssw AS (
    SELECT SUM(POWER(em."log_expression" - gs.mean_j, 2)) AS ssw
    FROM
        expr_mut em
    JOIN
        group_stats gs
        ON em."Variant_Classification" = gs."Variant_Classification"
),
degrees AS (
    SELECT
        (SELECT COUNT(*) FROM expr_mut) AS N,
        (SELECT COUNT(*) FROM group_stats) AS k
),
anova AS (
    SELECT
        ssb.ssb,
        ssw.ssw,
        degrees.N,
        degrees.k,
        (degrees.k - 1) AS df_between,
        (degrees.N - degrees.k) AS df_within,
        (ssb.ssb / NULLIF((degrees.k - 1), 0)) AS msb,
        (ssw.ssw / NULLIF((degrees.N - degrees.k), 0)) AS msw,
        (ssb.ssb / NULLIF((degrees.k - 1), 0)) / (ssw.ssw / NULLIF((degrees.N - degrees.k), 0)) AS F_statistic
    FROM
        ssb, ssw, degrees
)
SELECT
    anova.N AS "Total_samples",
    anova.k AS "Number_of_mutation_types",
    ROUND(anova.msb, 4) AS "Mean_square_between",
    ROUND(anova.msw, 4) AS "Mean_square_within",
    ROUND(anova.F_statistic, 4) AS "F_statistic"
FROM
    anova
LIMIT 1;