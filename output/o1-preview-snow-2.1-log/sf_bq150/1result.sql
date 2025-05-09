WITH expr AS (
    SELECT
        "sample_barcode",
        LOG(10, "normalized_count") AS "log_expression"
    FROM TCGA_HG19_DATA_V0.TCGA_HG19_DATA_V0."RNASEQ_GENE_EXPRESSION_UNC_RSEM"
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "HGNC_gene_symbol" = 'TP53'
      AND "normalized_count" > 0
),

mut AS (
    SELECT DISTINCT
        "sample_barcode_tumor" AS "sample_barcode",
        "Variant_Classification"
    FROM TCGA_HG19_DATA_V0.TCGA_HG19_DATA_V0."SOMATIC_MUTATION_MC3"
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "Hugo_Symbol" = 'TP53'
),

data AS (
    SELECT
        expr."sample_barcode",
        expr."log_expression",
        COALESCE(mut."Variant_Classification", 'Wild_Type') AS "Mutation_Type"
    FROM expr
    LEFT JOIN mut ON expr."sample_barcode" = mut."sample_barcode"
),

group_stats AS (
    SELECT
        "Mutation_Type",
        COUNT(*) AS "n_j",
        AVG("log_expression") AS "mean_j"
    FROM data
    GROUP BY "Mutation_Type"
),

overall_stats AS (
    SELECT
        COUNT(*) AS N,
        AVG("log_expression") AS "grand_mean"
    FROM data
),

degrees AS (
    SELECT
        overall_stats.N AS N,
        (SELECT COUNT(*) FROM group_stats) AS k,
        (SELECT COUNT(*) FROM group_stats) - 1 AS df_between,
        overall_stats.N - (SELECT COUNT(*) FROM group_stats) AS df_within
    FROM overall_stats
),

ssb AS (
    SELECT SUM("n_j" * POWER("mean_j" - overall_stats."grand_mean", 2)) AS "SSB"
    FROM group_stats, overall_stats
),

ssw AS (
    SELECT SUM(POWER(data."log_expression" - group_stats."mean_j", 2)) AS "SSW"
    FROM data
    JOIN group_stats ON data."Mutation_Type" = group_stats."Mutation_Type"
),

ms AS (
    SELECT
        degrees.N AS "Total_samples",
        degrees.k AS "Number_of_mutation_types",
        ssb."SSB" / degrees.df_between AS "Mean_square_between",
        ssw."SSW" / degrees.df_within AS "Mean_square_within",
        (ssb."SSB" / degrees.df_between) / (ssw."SSW" / degrees.df_within) AS "F_statistic"
    FROM ssb, ssw, degrees
)

SELECT
    "Total_samples",
    "Number_of_mutation_types",
    ROUND("Mean_square_between", 4) AS "Mean_square_between",
    ROUND("Mean_square_within", 4) AS "Mean_square_within",
    ROUND("F_statistic", 4) AS "F_statistic"
FROM ms;