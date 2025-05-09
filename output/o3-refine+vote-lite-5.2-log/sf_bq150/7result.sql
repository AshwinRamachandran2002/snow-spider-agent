WITH 
/*--- 1.  log10‑transformed TP53 expression for TCGA‑BRCA --------------------*/
expr AS (
    SELECT 
        "sample_barcode"                              AS sample_barcode,
        LOG(10, "normalized_count")                   AS log_expr           -- log10‑transform
    FROM TCGA_HG19_DATA_V0.TCGA_HG19_DATA_V0.RNASEQ_GENE_EXPRESSION_UNC_RSEM
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "HGNC_gene_symbol"  = 'TP53'
      AND "normalized_count"  > 0
),
/*--- 2.  TP53 mutation type (Variant_Classification) per tumour sample -----*/
mut AS (
    SELECT 
        "sample_barcode_tumor"                        AS sample_barcode,
        MIN("Variant_Classification")                 AS variant_class      -- take a single class if >1
    FROM TCGA_HG19_DATA_V0.TCGA_HG19_DATA_V0.SOMATIC_MUTATION_MC3
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "Hugo_Symbol"       = 'TP53'
    GROUP BY "sample_barcode_tumor"
),
/*--- 3.  Merge expression with mutation; flag wild‑type samples ------------*/
data AS (
    SELECT 
        e.sample_barcode,
        COALESCE(m.variant_class, 'No_Mutation')      AS mutation_type,
        e.log_expr
    FROM expr e
    LEFT JOIN mut m
           ON e.sample_barcode = m.sample_barcode
),
/*--- 4.  Per‑group counts & means ------------------------------------------*/
group_stats AS (
    SELECT 
        mutation_type,
        COUNT(*)                AS n_j,
        AVG(log_expr)           AS mean_j
    FROM data
    GROUP BY mutation_type
),
/*--- 5.  Grand totals -------------------------------------------------------*/
grand AS (
    SELECT 
        COUNT(*)                AS N,
        AVG(log_expr)           AS grand_mean
    FROM data
),
/*--- 6.  Sum of Squares Between groups -------------------------------------*/
ssb AS (
    SELECT 
        SUM(n_j * POWER(mean_j - (SELECT grand_mean FROM grand), 2)) 
                                AS ss_between
    FROM group_stats
),
/*--- 7.  Sum of Squares Within groups --------------------------------------*/
ssw AS (
    SELECT 
        SUM(POWER(d.log_expr - gs.mean_j, 2)) 
                                AS ss_within
    FROM data        d
    JOIN group_stats gs
      ON d.mutation_type = gs.mutation_type
),
/*--- 8.  Combine and compute ANOVA metrics ---------------------------------*/
calc AS (
    SELECT
        g.N                                           AS total_samples,
        k.k                                           AS num_mutation_types,
        sb.ss_between                                 AS ssb,
        sw.ss_within                                  AS ssw,
        sb.ss_between / (k.k - 1)                     AS msb,
        sw.ss_within / (g.N - k.k)                    AS msw
    FROM grand g
    CROSS JOIN (SELECT COUNT(*) AS k FROM group_stats) k
    CROSS JOIN ssb sb
    CROSS JOIN ssw sw
)
/*--- 9.  Final output -------------------------------------------------------*/
SELECT
    total_samples,
    num_mutation_types,
    ROUND(msb, 4)            AS mean_square_between,
    ROUND(msw, 4)            AS mean_square_within,
    ROUND(msb / msw, 4)      AS f_statistic
FROM calc;