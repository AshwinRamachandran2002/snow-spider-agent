/*  ------------  One-way ANOVA: TP53 log10 expression vs mutation class (TCGA-BRCA)  ------------ */
WITH expr AS (      /* 1. log10-transformed TP53 expression in primary-tumour samples */
    SELECT
        "sample_barcode"                           AS SAMPLE_BARCODE,
        LOG(10, "normalized_count")                AS LOG_EXP
    FROM TCGA_HG19_DATA_V0.TCGA_HG19_DATA_V0.RNASEQ_GENE_EXPRESSION_UNC_RSEM
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "HGNC_gene_symbol"   = 'TP53'
      AND "normalized_count"  > 0
      AND REGEXP_LIKE("sample_barcode", '-01A$')                      -- primary-tumour
),
muts AS (       /* 2. one mutation type per sample (or NULL if wild-type) */
    SELECT
        "sample_barcode_tumor"                     AS SAMPLE_BARCODE,
        MAX("Variant_Classification")              AS MUT_TYPE
    FROM TCGA_HG19_DATA_V0.TCGA_HG19_DATA_V0.SOMATIC_MUTATION_MC3
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "Hugo_Symbol"       = 'TP53'
    GROUP BY "sample_barcode_tumor"
),
expr_mut AS (   /* 3. merge expression with mutation label */
    SELECT
        e.SAMPLE_BARCODE,
        e.LOG_EXP,
        COALESCE(m.MUT_TYPE, 'Wild_Type')          AS MUT_TYPE
    FROM expr e
    LEFT JOIN muts m
          ON e.SAMPLE_BARCODE = m.SAMPLE_BARCODE
),
grand AS (      /* 4. grand mean & total N */
    SELECT
        COUNT(*)        AS N,
        AVG(LOG_EXP)    AS GRAND_MEAN
    FROM expr_mut
),
group_stats AS (/* 5. n_j and mean_j for each mutation class */
    SELECT
        MUT_TYPE,
        COUNT(*)        AS N_J,
        AVG(LOG_EXP)    AS MEAN_J
    FROM expr_mut
    GROUP BY MUT_TYPE
),
ssb AS (        /* 6. sum-of-squares between groups */
    SELECT
        SUM(N_J * POWER(MEAN_J - g.GRAND_MEAN, 2)) AS SS_BETWEEN
    FROM group_stats, grand g
),
sst AS (        /* 7. total sum-of-squares */
    SELECT
        SUM(POWER(LOG_EXP - g.GRAND_MEAN, 2))      AS SS_TOTAL
    FROM expr_mut, grand g
),
calc AS (       /* 8. ANOVA components */
    SELECT
        g.N                                             AS TOTAL_SAMPLES,
        (SELECT COUNT(*) FROM group_stats)              AS K,
        sb.SS_BETWEEN                                   AS SS_BETWEEN,
        st.SS_TOTAL - sb.SS_BETWEEN                     AS SS_WITHIN
    FROM grand g, ssb sb, sst st
),
anova AS (      /* 9. mean squares & F-statistic */
    SELECT
        TOTAL_SAMPLES,
        K                                              AS MUTATION_TYPES,
        SS_BETWEEN / (K - 1)                           AS MS_BETWEEN,
        SS_WITHIN  / (TOTAL_SAMPLES - K)               AS MS_WITHIN,
        (SS_BETWEEN / (K - 1)) /
        (SS_WITHIN  / (TOTAL_SAMPLES - K))             AS F_STATISTIC
    FROM calc
)
SELECT
    TOTAL_SAMPLES                AS "TOTAL_SAMPLES",
    MUTATION_TYPES               AS "MUTATION_TYPES",
    ROUND(MS_BETWEEN, 4)         AS "MEAN_SQUARE_BETWEEN",
    ROUND(MS_WITHIN, 4)          AS "MEAN_SQUARE_WITHIN",
    ROUND(F_STATISTIC, 4)        AS "F_STATISTIC"
FROM anova;