WITH expr AS (   -- log10-transformed TP53 mRNA expression in TCGA-BRCA
    SELECT
        "sample_barcode",
        LOG(10 , "normalized_count")                   AS log_expr      -- LOG(base , value)
    FROM TCGA_HG19_DATA_V0.TCGA_HG19_DATA_V0.RNASEQ_GENE_EXPRESSION_UNC_RSEM
    WHERE "project_short_name"   = 'TCGA-BRCA'
      AND "HGNC_gene_symbol"     = 'TP53'
      AND "normalized_count"     > 0
), mut AS (       -- mutation category per sample (if any TP53 mutation)
    SELECT
        "sample_barcode_tumor"                         AS sample_barcode,
        MIN("Variant_Classification")                  AS mut_type      -- choose one if multiple
    FROM TCGA_HG19_DATA_V0.TCGA_HG19_DATA_V0.SOMATIC_MUTATION_MC3
    WHERE "project_short_name"   = 'TCGA-BRCA'
      AND "Hugo_Symbol"          = 'TP53'
    GROUP BY "sample_barcode_tumor"
), data AS (      -- merge expression with mutation class; mark wild-type
    SELECT
        e."sample_barcode",
        COALESCE(m.mut_type , 'Wild_Type')             AS mut_type,
        e.log_expr
    FROM expr e
    LEFT JOIN mut m
           ON e."sample_barcode" = m.sample_barcode
), group_stats AS (      -- per-mutation-type aggregates
    SELECT
        mut_type,
        COUNT(*)::FLOAT                                AS n_g,
        AVG(log_expr)                                  AS mean_g,
        SUM(POWER(log_expr,2))                         AS sum_sq_g
    FROM data
    GROUP BY mut_type
), agg1 AS (      -- overall counts and grand mean
    SELECT
        SUM(n_g)                                       AS N,
        COUNT(*)                                       AS k,
        SUM(n_g*mean_g)/SUM(n_g)                       AS grand_mean
    FROM group_stats
), agg2 AS (      -- compute SSB and SSW
    SELECT
        a.N,
        a.k,
        SUM(gs.n_g * POWER(gs.mean_g - a.grand_mean,2))                AS ssb,
        SUM(gs.sum_sq_g - gs.n_g * POWER(gs.mean_g,2))                 AS ssw
    FROM group_stats gs, agg1 a
    GROUP BY a.N, a.k
)
SELECT
    N                                   AS total_samples,
    k                                   AS mutation_type_count,
    ssb/(k - 1)                         AS mean_square_between,
    ssw/(N - k)                         AS mean_square_within,
    (ssb/(k - 1))/(ssw/(N - k))         AS f_statistic
FROM agg2;