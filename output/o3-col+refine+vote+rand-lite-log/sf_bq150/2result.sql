/* One-way ANOVA for log10-TP53 expression across TP53 mutation classes in TCGA-BRCA */
WITH joined AS (   -- expression joined with mutation class (null → 'Wildtype')
    SELECT
        COALESCE(m."Variant_Classification", 'Wildtype') AS mut_type,
        LOG(10, e."normalized_count")                    AS log_expr   -- log10-TP53
    FROM TCGA_HG19_DATA_V0.TCGA_HG19_DATA_V0.RNASEQ_GENE_EXPRESSION_UNC_RSEM  e
    LEFT JOIN TCGA_HG19_DATA_V0.TCGA_HG19_DATA_V0.SOMATIC_MUTATION_MC3        m
           ON e."sample_barcode" = m."sample_barcode_tumor"
          AND m."project_short_name" = 'TCGA-BRCA'
          AND m."Hugo_Symbol"        = 'TP53'
    WHERE e."project_short_name" = 'TCGA-BRCA'
      AND e."HGNC_gene_symbol"   = 'TP53'
      AND e."normalized_count"   > 0
),
stats AS (   -- overall counts & grand mean
    SELECT
        COUNT(*)                  AS N,
        COUNT(DISTINCT mut_type)  AS k,
        AVG(log_expr)             AS grand_mean
    FROM joined
),
grp AS (     -- per-group counts & means
    SELECT
        mut_type,
        COUNT(*)                 AS n_j,
        AVG(log_expr)            AS mean_j,
        SUM(POWER(log_expr, 2))  AS sumsq_j
    FROM joined
    GROUP BY mut_type
),
ss AS (      -- sums of squares
    SELECT
        SUM(n_j * POWER(mean_j - (SELECT grand_mean FROM stats), 2)) AS ss_between,
        SUM(sumsq_j - n_j * POWER(mean_j, 2))                        AS ss_within
    FROM grp
)
SELECT
    stats.N                                                          AS total_samples,
    stats.k                                                          AS n_mutation_types,
    ROUND(ss.ss_between / (stats.k - 1), 6)                          AS mean_square_between,
    ROUND(ss.ss_within  / (stats.N - stats.k), 6)                    AS mean_square_within,
    ROUND(
        (ss.ss_between / (stats.k - 1)) /
        (ss.ss_within  / (stats.N - stats.k)
    ), 6)                                                            AS f_statistic
FROM stats
CROSS JOIN ss;