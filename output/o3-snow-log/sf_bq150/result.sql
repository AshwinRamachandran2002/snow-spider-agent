WITH expr AS (
    SELECT 
        "sample_barcode",
        LOG(10, "normalized_count")                  AS log_expr   -- base-10 logarithm
    FROM TCGA_HG19_DATA_V0.TCGA_HG19_DATA_V0."RNASEQ_GENE_EXPRESSION_UNC_RSEM"
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "HGNC_gene_symbol"   = 'TP53'
      AND "normalized_count" IS NOT NULL
      AND "normalized_count" > 0
), 
mut AS (
    /* one mutation type per sample (if any) */
    SELECT 
        "sample_barcode_tumor"                       AS sample_barcode,
        MIN("Variant_Classification")                AS variant_class
    FROM TCGA_HG19_DATA_V0.TCGA_HG19_DATA_V0."SOMATIC_MUTATION_MC3"
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "Hugo_Symbol"       = 'TP53'
    GROUP BY "sample_barcode_tumor"
), 
group_assign AS (
    SELECT 
        e."sample_barcode",
        e.log_expr,
        COALESCE(m.variant_class, 'Wild_Type')       AS group_label
    FROM expr e
    LEFT JOIN mut m
           ON e."sample_barcode" = m.sample_barcode
), 
group_stats AS (
    SELECT 
        group_label,
        COUNT(*)                                     AS n_j,
        AVG(log_expr)                                AS mean_j
    FROM group_assign
    GROUP BY group_label
), 
overall AS (
    SELECT 
        AVG(log_expr)                                AS grand_mean,
        COUNT(*)                                     AS N
    FROM group_assign
), 
ssb_calc AS (
    SELECT 
        SUM(gs.n_j * POWER(gs.mean_j - o.grand_mean, 2)) AS ssb
    FROM group_stats gs
    CROSS JOIN overall o
), 
ssw_calc AS (
    SELECT 
        SUM(POWER(ga.log_expr - gs.mean_j, 2))       AS ssw
    FROM group_assign ga
    JOIN group_stats gs 
      ON ga.group_label = gs.group_label
), 
df AS (
    SELECT 
        (SELECT COUNT(DISTINCT group_label) FROM group_assign)  AS k,
        (SELECT N FROM overall)                                 AS N
), 
final AS (
    SELECT 
        df.N                                                   AS total_samples,
        df.k                                                   AS mutation_types,
        ssb_calc.ssb / (df.k - 1)                              AS mean_square_between,
        ssw_calc.ssw / (df.N - df.k)                           AS mean_square_within,
        (ssb_calc.ssb / (df.k - 1)) / 
        (ssw_calc.ssw / (df.N - df.k))                         AS f_statistic
    FROM df, ssb_calc, ssw_calc
)
SELECT 
    total_samples,
    mutation_types,
    mean_square_between,
    mean_square_within,
    f_statistic
FROM final;