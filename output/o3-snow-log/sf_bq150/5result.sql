/* One-way ANOVA of log10-transformed TP53 expression across mutation classes
   in TCGA-BRCA                                                          */

WITH
/* 1. Expression values (one row per sample, log10 transformed) */
expr AS (
    SELECT
        "sample_barcode"                           AS sample_barcode,
        AVG( LOG("normalized_count", 10) )         AS log_expr          -- average if >1 aliquot
    FROM TCGA_HG19_DATA_V0.TCGA_HG19_DATA_V0.RNASEQ_GENE_EXPRESSION_UNC_RSEM
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "HGNC_gene_symbol"   = 'TP53'
      AND "normalized_count"   > 0
    GROUP BY "sample_barcode"
),

/* 2. Mutation class per sample (Variant_Classification for TP53, else WT) */
mut AS (
    SELECT
        "sample_barcode_tumor"                     AS sample_barcode,
        MIN("Variant_Classification")              AS mutation_type     -- choose any if >1
    FROM TCGA_HG19_DATA_V0.TCGA_HG19_DATA_V0.SOMATIC_MUTATION_MC3
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "Hugo_Symbol"        = 'TP53'
    GROUP BY "sample_barcode_tumor"
),

/* 3. Combine expression with mutation label; assign ‘Wild_Type’ when no mutation */
combo AS (
    SELECT
        e.sample_barcode,
        e.log_expr,
        COALESCE(m.mutation_type , 'Wild_Type')    AS mutation_type
    FROM expr e
    LEFT JOIN mut m
           ON e.sample_barcode = m.sample_barcode
),

/* 4. Per-group summaries */
grp AS (
    SELECT
        mutation_type,
        COUNT(*)                          AS n_j,
        AVG(log_expr)                     AS mean_j,
        SUM(POWER(log_expr, 2))           AS ssq_j            -- Σx² for group
    FROM combo
    GROUP BY mutation_type
),

/* 5. Overall counts & grand mean */
overall AS (
    SELECT
        COUNT(*)                          AS N,
        COUNT(DISTINCT mutation_type)     AS k,
        AVG(log_expr)                     AS grand_mean
    FROM combo
),

/* 6. SSB and SSW */
ss AS (
    SELECT
        /* Between-groups sum of squares */
        SUM( n_j * POWER(mean_j - (SELECT grand_mean FROM overall), 2) )        AS ssb,
        /* Within-groups sum of squares */
        SUM( ssq_j - n_j * POWER(mean_j, 2) )                                   AS ssw
    FROM grp
),

/* 7. Mean squares and F-statistic */
anova AS (
    SELECT
        (SELECT N FROM overall)                                   AS N,
        (SELECT k FROM overall)                                   AS k,
        ssb,
        ssw,
        ssb / ( (SELECT k FROM overall) - 1 )                     AS msb,
        ssw / ( (SELECT N FROM overall) - (SELECT k FROM overall) ) AS msw
    FROM ss
)

SELECT
    N                                    AS "total_samples",
    k                                    AS "mutation_type_count",
    ROUND(msb , 4)                       AS "mean_square_between",
    ROUND(msw , 4)                       AS "mean_square_within",
    ROUND(msb / msw , 4)                 AS "F_statistic"
FROM anova;