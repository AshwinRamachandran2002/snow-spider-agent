WITH expression AS (
    SELECT
        "sample_barcode",
        LOG(10, "normalized_count") AS log10_expr
    FROM "TCGA_HG19_DATA_V0"."TCGA_HG19_DATA_V0"."RNASEQ_GENE_EXPRESSION_UNC_RSEM"
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "HGNC_gene_symbol"   = 'TP53'
      AND "normalized_count"  > 0
),
mutations AS (
    SELECT
        "sample_barcode_tumor"   AS sample_barcode,
        "Variant_Classification" AS variant_class
    FROM "TCGA_HG19_DATA_V0"."TCGA_HG19_DATA_V0"."SOMATIC_MUTATION_MC3"
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "Hugo_Symbol"        = 'TP53'
),
combined AS (
    SELECT
        e."sample_barcode",
        COALESCE(MIN(m.variant_class), 'No_Mutation') AS mutation_type,
        e.log10_expr
    FROM expression e
    LEFT JOIN mutations m
           ON m.sample_barcode = e."sample_barcode"
    GROUP BY e."sample_barcode", e.log10_expr
),
group_stats AS (
    SELECT
        mutation_type,
        COUNT(*)        AS n_j,
        AVG(log10_expr) AS mean_j
    FROM combined
    GROUP BY mutation_type
),
overall AS (
    SELECT
        COUNT(*)        AS N,
        AVG(log10_expr) AS grand_mean
    FROM combined
),
ssb AS (
    SELECT
        SUM(n_j * POWER(mean_j - (SELECT grand_mean FROM overall), 2)) AS ss_between
    FROM group_stats
),
ssw AS (
    SELECT
        SUM(POWER(c.log10_expr - g.mean_j, 2)) AS ss_within
    FROM combined c
    JOIN group_stats g ON g.mutation_type = c.mutation_type
),
dof AS (
    SELECT
        (SELECT COUNT(*) FROM group_stats) - 1 AS df_between,
        (SELECT N FROM overall) - (SELECT COUNT(*) FROM group_stats) AS df_within
),
ms AS (
    SELECT
        (SELECT ss_between FROM ssb) / (SELECT df_between FROM dof) AS ms_between,
        (SELECT ss_within  FROM ssw) / (SELECT df_within  FROM dof) AS ms_within
)
SELECT
    (SELECT N FROM overall)                            AS total_samples,
    (SELECT COUNT(*) FROM group_stats)                 AS mutation_types,
    ROUND(ms_between, 4)                               AS mean_square_between,
    ROUND(ms_within, 4)                                AS mean_square_within,
    ROUND(ms_between / ms_within, 4)                   AS F_statistic
FROM ms;