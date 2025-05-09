WITH expr AS (   -- log10-transformed TP53 expression per BRCA sample
    SELECT
        "sample_barcode",
        AVG(LOG(10, "normalized_count")) AS log_expr
    FROM TCGA_HG19_DATA_V0.TCGA_HG19_DATA_V0.RNASEQ_GENE_EXPRESSION_UNC_RSEM
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "HGNC_gene_symbol" = 'TP53'
      AND "normalized_count" IS NOT NULL
      AND "normalized_count" > 0
    GROUP BY "sample_barcode"
),
mut AS (         -- one mutation type per sample (if any)
    SELECT
        "sample_barcode_tumor" AS sample_barcode,
        MIN("Variant_Classification") AS mutation_type
    FROM TCGA_HG19_DATA_V0.TCGA_HG19_DATA_V0.SOMATIC_MUTATION_MC3
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "Hugo_Symbol" = 'TP53'
      AND "Variant_Classification" IS NOT NULL
    GROUP BY "sample_barcode_tumor"
),
combined AS (    -- merge expression with mutation, assign Wild_Type if none
    SELECT
        e."sample_barcode",
        COALESCE(m.mutation_type, 'Wild_Type') AS mutation_type,
        e.log_expr
    FROM expr e
    LEFT JOIN mut m
      ON e."sample_barcode" = m.sample_barcode
),
group_stats AS ( -- nⱼ and meanⱼ for each mutation class
    SELECT
        mutation_type,
        COUNT(*)      AS n_j,
        AVG(log_expr) AS mean_j
    FROM combined
    GROUP BY mutation_type
),
grand AS (       -- grand mean and total N
    SELECT
        AVG(log_expr) AS grand_mean,
        COUNT(*)      AS N
    FROM combined
),
ssb AS (         -- between-group sum of squares
    SELECT
        SUM(gs.n_j * POWER(gs.mean_j - g.grand_mean, 2)) AS ssb
    FROM group_stats gs
    CROSS JOIN grand g
),
ssw AS (         -- within-group sum of squares
    SELECT
        SUM(POWER(c.log_expr - gs.mean_j, 2)) AS ssw
    FROM combined c
    JOIN group_stats gs
      ON c.mutation_type = gs.mutation_type
),
final AS (       -- ANOVA components
    SELECT
        g.N                              AS total_samples,
        k.k                              AS num_mutation_types,
        ssb.ssb / (k.k - 1)              AS ms_between,
        ssw.ssw / (g.N - k.k)            AS ms_within,
        (ssb.ssb / (k.k - 1)) /
        (ssw.ssw / (g.N - k.k))          AS f_statistic
    FROM grand g
    CROSS JOIN ssb
    CROSS JOIN ssw
    CROSS JOIN (SELECT COUNT(*) AS k FROM group_stats) k
)
SELECT
    total_samples,
    num_mutation_types,
    ROUND(ms_between, 4) AS mean_square_between,
    ROUND(ms_within, 4)  AS mean_square_within,
    ROUND(f_statistic, 4) AS f_statistic
FROM final;