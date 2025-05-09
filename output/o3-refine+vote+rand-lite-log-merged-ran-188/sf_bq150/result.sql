WITH
/* ───────────────────── 1. TP53 expression (tumour samples, BRCA) ───────────────────── */
expr AS (
    SELECT
        "sample_barcode"                       AS sample_barcode,
        LOG(10, "normalized_count")            AS log_exp          -- base‑10 log
    FROM   "TCGA_HG19_DATA_V0"."TCGA_HG19_DATA_V0"."RNASEQ_GENE_EXPRESSION_UNC_RSEM"
    WHERE  "project_short_name" = 'TCGA-BRCA'
      AND  "HGNC_gene_symbol"  = 'TP53'
      AND  "normalized_count"  > 0
),
/* ───────────────────── 2. First TP53 mutation type per sample ─────────────────────── */
mut AS (
    SELECT
        "sample_barcode_tumor"                 AS sample_barcode,
        MIN("Variant_Classification")          AS mutation_type
    FROM   "TCGA_HG19_DATA_V0"."TCGA_HG19_DATA_V0"."SOMATIC_MUTATION_MC3"
    WHERE  "project_short_name" = 'TCGA-BRCA'
      AND  "Hugo_Symbol"        = 'TP53'
    GROUP  BY "sample_barcode_tumor"
),
/* ───────────────────── 3. Merge; assign Wildtype when no mutation ─────────────────── */
merged AS (
    SELECT
        e.sample_barcode,
        COALESCE(m.mutation_type, 'Wildtype')  AS mutation_type,
        e.log_exp
    FROM   expr e
    LEFT   JOIN mut m
           ON e.sample_barcode = m.sample_barcode
),
/* ───────────────────── 4. Per‑group counts & means ────────────────────────────────── */
grp_stats AS (
    SELECT
        mutation_type,
        COUNT(*)                  AS n_j,
        AVG(log_exp)              AS mean_j
    FROM   merged
    GROUP  BY mutation_type
),
/* ───────────────────── 5. Grand totals ────────────────────────────────────────────── */
grand AS (
    SELECT
        COUNT(*)   AS N,
        AVG(log_exp) AS grand_mean
    FROM   merged
),
ssb AS (  -- between‑group sum of squares
    SELECT SUM(gp.n_j * POWER(gp.mean_j - gr.grand_mean, 2)) AS ssb
    FROM   grp_stats gp, grand gr
),
ssw AS (  -- within‑group sum of squares
    SELECT SUM(POWER(m.log_exp - gp.mean_j, 2)) AS ssw
    FROM   merged m
    JOIN   grp_stats gp ON m.mutation_type = gp.mutation_type
),
k_cnt AS (SELECT COUNT(*) AS k FROM grp_stats)
/* ───────────────────── 6. Final ANOVA statistics ─────────────────────────────────── */
SELECT
    gr.N                                        AS "TOTAL_SAMPLES",
    kc.k                                        AS "MUTATION_TYPES",
    ssb.ssb / (kc.k - 1)        AS "MEAN_SQUARE_BETWEEN",
    ssw.ssw / (gr.N - kc.k)     AS "MEAN_SQUARE_WITHIN",
    (ssb.ssb / (kc.k - 1)) /
    (ssw.ssw / (gr.N - kc.k))   AS "F_STATISTIC"
FROM grand gr
JOIN k_cnt kc ON 1=1
JOIN ssb    ON 1=1
JOIN ssw    ON 1=1;