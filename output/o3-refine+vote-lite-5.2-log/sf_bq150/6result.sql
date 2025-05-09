WITH expr AS (   -- TP53 expression (log10 transformed) in TCGA‑BRCA
    SELECT 
        "sample_barcode",
        LOG(10, "normalized_count")                     AS log_expr
    FROM TCGA_HG19_DATA_V0.TCGA_HG19_DATA_V0.RNASEQ_GENE_EXPRESSION_UNC_RSEM
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "HGNC_gene_symbol"   = 'TP53'
      AND "normalized_count"   > 0
), 
mut AS (         -- TP53 mutation type per sample (if any)
    SELECT 
        "sample_barcode_tumor"                         AS sample_barcode,
        MIN("Variant_Classification")                  AS mutation_type
    FROM TCGA_HG19_DATA_V0.TCGA_HG19_DATA_V0.SOMATIC_MUTATION_MC3
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "Hugo_Symbol"         = 'TP53'
    GROUP BY "sample_barcode_tumor"
),
data AS (        -- merge expression with mutation status
    SELECT
        e."sample_barcode",
        e.log_expr,
        COALESCE(m.mutation_type, 'NO_MUTATION')       AS mutation_type
    FROM expr e
    LEFT JOIN mut m
      ON e."sample_barcode" = m.sample_barcode
),
group_stats AS ( -- per‑mutation‑type statistics
    SELECT
        mutation_type,
        COUNT(*)                                       AS n,
        AVG(log_expr)                                  AS mean_expr,
        VAR_SAMP(log_expr)                             AS var_expr          -- NULL if n=1
    FROM data
    GROUP BY mutation_type
),
summary AS (     -- global counts and grand mean
    SELECT
        SUM(n)                                         AS total_samples,
        COUNT(*)                                       AS mutation_type_count,
        (SELECT AVG(log_expr) FROM data)               AS grand_mean
    FROM group_stats
),
ssb AS (         -- sum of squares between groups
    SELECT 
        SUM(gs.n * POWER(gs.mean_expr - (SELECT grand_mean FROM summary), 2))
        AS ss_between
    FROM group_stats gs
),
ssw AS (         -- sum of squares within groups
    SELECT 
        SUM( (gs.n - 1) * COALESCE(gs.var_expr, 0) )   AS ss_within
    FROM group_stats gs
),
final AS (
    SELECT
        s.total_samples,
        s.mutation_type_count,
        ssb.ss_between / (s.mutation_type_count - 1)                       AS mean_square_between,
        ssw.ss_within / (s.total_samples - s.mutation_type_count)          AS mean_square_within,
        (ssb.ss_between / (s.mutation_type_count - 1)) /
        NULLIF(
            (ssw.ss_within / (s.total_samples - s.mutation_type_count)),
            0
        )                                                                  AS f_statistic
    FROM summary s
    CROSS JOIN ssb
    CROSS JOIN ssw
)
SELECT 
    total_samples,
    mutation_type_count,
    mean_square_between,
    mean_square_within,
    f_statistic
FROM final;