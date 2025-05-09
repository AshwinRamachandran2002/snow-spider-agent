WITH expr AS (  -- TP53 gene‑expression values
    SELECT 
        "sample_barcode",
        "normalized_count"
    FROM TCGA_HG19_DATA_V0.TCGA_HG19_DATA_V0.RNASEQ_GENE_EXPRESSION_UNC_RSEM
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "HGNC_gene_symbol"  = 'TP53'
      AND "normalized_count"  > 0
), expr_log AS (  -- log10‑transformed expression
    SELECT
        "sample_barcode",
        LOG("normalized_count", 10)           AS log_expr   -- base‑10 log
    FROM expr
), mut AS (  -- mutation type for TP53 per sample
    SELECT
        "sample_barcode_tumor"                AS sample_barcode,
        MIN("Variant_Classification")         AS variant_class    -- if multiple, pick one deterministically
    FROM TCGA_HG19_DATA_V0.TCGA_HG19_DATA_V0.SOMATIC_MUTATION_MC3
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "Hugo_Symbol"       = 'TP53'
    GROUP BY "sample_barcode_tumor"
), sample_data AS (  -- merge expression & mutation, default to Wild_Type
    SELECT
        e."sample_barcode",
        e.log_expr,
        COALESCE(m.variant_class, 'Wild_Type') AS mut_type
    FROM expr_log e
    LEFT JOIN mut m
           ON e."sample_barcode" = m.sample_barcode
), group_stats AS (  -- per‑mutation‑type stats
    SELECT
        mut_type,
        COUNT(*)        AS n_j,
        AVG(log_expr)   AS mean_j
    FROM sample_data
    GROUP BY mut_type
), grand AS (
    SELECT 
        COUNT(*)        AS total_n,
        AVG(log_expr)   AS grand_mean
    FROM sample_data
), ssb AS (  -- sum of squares between groups
    SELECT
        SUM(g.n_j * POWER(g.mean_j - gr.grand_mean, 2)) AS ss_between
    FROM group_stats g
    CROSS JOIN grand gr
), ssw AS (  -- sum of squares within groups
    SELECT
        SUM(POWER(s.log_expr - g.mean_j, 2))            AS ss_within
    FROM sample_data s
    JOIN group_stats g
      ON s.mut_type = g.mut_type
), df AS (
    SELECT
        (SELECT COUNT(*) FROM group_stats) AS k,
        (SELECT total_n  FROM grand)       AS n
), ms AS (  -- mean squares
    SELECT
        df.n                               AS total_samples,
        df.k                               AS mutation_types,
        ssb.ss_between                     AS ssb,
        ssw.ss_within                      AS ssw,
        (df.k - 1)                         AS df_between,
        (df.n - df.k)                      AS df_within,
        ssb.ss_between / (df.k - 1)        AS ms_between,
        ssw.ss_within / (df.n - df.k)      AS ms_within
    FROM df
    CROSS JOIN ssb
    CROSS JOIN ssw
)
SELECT
    total_samples,
    mutation_types,
    ROUND(ms_between, 4)                          AS mean_square_between,
    ROUND(ms_within, 4)                           AS mean_square_within,
    ROUND(ms_between / ms_within, 4)              AS f_statistic
FROM ms;