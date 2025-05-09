WITH
/* ───── 1.  TP53 expression (log10‑transformed) in TCGA‑BRCA tumour samples ───── */
expr AS (
    SELECT
        "sample_barcode",
        LOG(10, "normalized_count")        AS log_expr          -- base‑10 log
    FROM TCGA_HG19_DATA_V0.TCGA_HG19_DATA_V0."RNASEQ_GENE_EXPRESSION_UNC_RSEM"
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "HGNC_gene_symbol"  = 'TP53'
      AND "normalized_count"  > 0
      AND "sample_barcode" ILIKE '%-01%'        -- tumour samples
),
/* ───── 2.  TP53 mutation label per tumour sample ───── */
mut AS (
    SELECT
        "sample_barcode_tumor"          AS sample_barcode,
        MIN("Variant_Classification")   AS mutation_type      -- one type per sample
    FROM TCGA_HG19_DATA_V0.TCGA_HG19_DATA_V0."SOMATIC_MUTATION_MC3"
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "Hugo_Symbol"        = 'TP53'
    GROUP BY "sample_barcode_tumor"
),
/* ───── 3.  Merge expression with mutation label (assign Wild_Type when none) ───── */
combined AS (
    SELECT
        e."sample_barcode",
        e.log_expr,
        COALESCE(m.mutation_type, 'Wild_Type') AS mutation_type
    FROM expr e
    LEFT JOIN mut m
      ON e."sample_barcode" = m.sample_barcode
),
/* ───── 4.  Overall statistics ───── */
grand_stats AS (
    SELECT
        COUNT(*)      AS N,
        AVG(log_expr) AS grand_mean
    FROM combined
),
/* ───── 5.  Group (mutation‑type) statistics ───── */
group_stats AS (
    SELECT
        mutation_type,
        COUNT(*)      AS n_j,
        AVG(log_expr) AS mean_j
    FROM combined
    GROUP BY mutation_type
),
/* ───── 6.  Sums of squares ───── */
ssb_cte AS (
    SELECT
        SUM(g.n_j * POWER(g.mean_j - gs.grand_mean, 2)) AS ssb
    FROM group_stats g
    CROSS JOIN grand_stats gs
),
ssw_cte AS (
    SELECT
        SUM(POWER(c.log_expr - g.mean_j, 2)) AS ssw
    FROM combined c
    JOIN group_stats g
      ON c.mutation_type = g.mutation_type
),
/* ───── 7.  Final ANOVA metrics ───── */
results AS (
    SELECT
        gs.N                                       AS sample_total,
        (SELECT COUNT(*) FROM group_stats)         AS mutation_type_count,
        ssb_cte.ssb                                AS ssb,
        ssw_cte.ssw                                AS ssw,
        ssb_cte.ssb / ((SELECT COUNT(*) FROM group_stats) - 1)             AS msb,
        ssw_cte.ssw / (gs.N - (SELECT COUNT(*) FROM group_stats))          AS msw
    FROM grand_stats gs
    CROSS JOIN ssb_cte
    CROSS JOIN ssw_cte
)
SELECT
    sample_total,
    mutation_type_count,
    ROUND(msb, 4)   AS mean_square_between,
    ROUND(msw, 4)   AS mean_square_within,
    ROUND(msb/msw, 4) AS f_statistic
FROM results;