WITH
/* 1. TP53 expression (log10-transformed) in TCGA-BRCA */
expr AS (
    SELECT
        "sample_barcode",
        LOG(10, "normalized_count")                     AS log_expr               -- log10
    FROM TCGA_HG19_DATA_V0.TCGA_HG19_DATA_V0."RNASEQ_GENE_EXPRESSION_UNC_RSEM"
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "HGNC_gene_symbol"   = 'TP53'
      AND "normalized_count"   > 0
),
/* 2. TP53 mutation classifications per sample in TCGA-BRCA */
mut AS (
    SELECT
        "sample_barcode_tumor"                          AS sample_barcode,
        "Variant_Classification"                        AS mutation_type
    FROM TCGA_HG19_DATA_V0.TCGA_HG19_DATA_V0."SOMATIC_MUTATION_MC3"
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "Hugo_Symbol"        = 'TP53'
),
/* 3. one mutation type per sample (if multiple, pick alphabetically) */
mut_agg AS (
    SELECT
        sample_barcode,
        MIN(mutation_type)                              AS mutation_type
    FROM mut
    GROUP BY sample_barcode
),
/* 4. merge expression with mutation label; absent mutations = Wild_Type */
combined AS (
    SELECT
        e."sample_barcode",
        e.log_expr,
        COALESCE(m.mutation_type, 'Wild_Type')          AS group_label
    FROM expr e
    LEFT JOIN mut_agg m
      ON e."sample_barcode" = m.sample_barcode
),
/* 5. grand summary statistics */
grand AS (
    SELECT
        COUNT(*)                                        AS n_total,
        AVG(log_expr)                                   AS grand_mean
    FROM combined
),
/* 6. per-group counts & means */
group_stats AS (
    SELECT
        group_label,
        COUNT(*)                                        AS n_j,
        AVG(log_expr)                                   AS mean_j
    FROM combined
    GROUP BY group_label
),
/* 7. between-group sum of squares */
ssb AS (
    SELECT
        SUM(n_j * POWER(mean_j - g.grand_mean, 2))      AS ss_between
    FROM group_stats
    CROSS JOIN grand g
),
/* 8. total sum of squares */
sst AS (
    SELECT
        SUM(POWER(log_expr - g.grand_mean, 2))          AS ss_total
    FROM combined
    CROSS JOIN grand g
),
/* 9. assemble ANOVA components */
anova AS (
    SELECT
        g.n_total                                       AS total_samples,
        (SELECT COUNT(*) FROM group_stats)              AS num_mutation_types,
        s.ss_between                                    AS ss_between,
        (st.ss_total - s.ss_between)                    AS ss_within
    FROM grand g
    CROSS JOIN ssb s
    CROSS JOIN sst st
)
/* 10. final output */
SELECT
    total_samples,
    num_mutation_types,
    ROUND(ss_between /(num_mutation_types - 1), 4)      AS mean_square_between,
    ROUND(ss_within /(total_samples - num_mutation_types), 4) AS mean_square_within,
    ROUND(
        (ss_between /(num_mutation_types - 1)) /
        (ss_within  /(total_samples - num_mutation_types))
    , 4)                                                AS f_statistic
FROM anova;