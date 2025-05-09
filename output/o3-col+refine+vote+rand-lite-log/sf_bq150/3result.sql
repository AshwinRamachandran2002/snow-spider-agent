/*-------------------------------------------------------------
   One-way ANOVA of log10-transformed TP53 expression (TCGA-BRCA)
   ─────────────────────────────────────────────────────────────
   Returns:  total_samples, mutation_types (k),
             mean_square_between, mean_square_within, F-statistic
-------------------------------------------------------------*/
WITH expr AS (    -- TP53 mRNA-seq expression (log10)
    SELECT
        "sample_barcode",
        LOG(10, NULLIF("normalized_count",0)) AS log10_expr
    FROM TCGA_HG19_DATA_V0.TCGA_HG19_DATA_V0."RNASEQ_GENE_EXPRESSION_UNC_RSEM"
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "HGNC_gene_symbol"   = 'TP53'
      AND "normalized_count"   > 0
),
mut AS (          -- per-sample mutation class for TP53
    SELECT
        "sample_barcode_tumor"              AS sample_barcode,
        MIN("Variant_Classification")       AS Variant_Classification   -- one label / sample
    FROM TCGA_HG19_DATA_V0.TCGA_HG19_DATA_V0."SOMATIC_MUTATION_MC3"
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "Hugo_Symbol"        = 'TP53'
    GROUP BY "sample_barcode_tumor"
),
merged AS (       -- expression joined to mutation label
    SELECT
        e."sample_barcode",
        COALESCE(m.Variant_Classification,'Wild_Type') AS mutation_type,
        e.log10_expr
    FROM expr  e
    LEFT JOIN mut m
      ON e."sample_barcode" = m.sample_barcode
),
stats AS (        -- per-group counts and means
    SELECT
        mutation_type,
        COUNT(*)        AS n_j,
        AVG(log10_expr) AS mean_j
    FROM merged
    GROUP BY mutation_type
),
grand AS (        -- overall sample count & grand mean
    SELECT
        COUNT(*)        AS N,
        AVG(log10_expr) AS grand_mean
    FROM merged
),
ss AS (           -- sums of squares
    SELECT
        -- Between groups
        (SELECT SUM(st.n_j * POWER(st.mean_j - g.grand_mean,2))
         FROM stats st, grand g)                       AS SSB,
        -- Within groups
        (SELECT SUM(POWER(m.log10_expr - st.mean_j,2))
         FROM merged m
         JOIN stats st
           ON m.mutation_type = st.mutation_type)      AS SSW
),
anova AS (
    SELECT
        g.N                                           AS total_samples,
        (SELECT COUNT(*) FROM stats)                  AS mutation_types,
        ss.SSB / ( (SELECT COUNT(*) FROM stats) - 1)  AS mean_square_between,
        ss.SSW / ( g.N - (SELECT COUNT(*) FROM stats))AS mean_square_within,
        (ss.SSB / ( (SELECT COUNT(*) FROM stats) - 1)) /
        (ss.SSW / ( g.N - (SELECT COUNT(*) FROM stats))) AS f_statistic
    FROM ss, grand g
)
SELECT
    total_samples,
    mutation_types,
    ROUND(mean_square_between,6)  AS mean_square_between,
    ROUND(mean_square_within,6)   AS mean_square_within,
    ROUND(f_statistic,6)          AS f_statistic
FROM anova;