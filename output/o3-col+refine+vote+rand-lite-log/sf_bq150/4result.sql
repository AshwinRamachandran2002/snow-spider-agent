/*  One–way ANOVA for log10-transformed TP53 expression
    across TP53 mutation classes in TCGA-BRCA samples         */
WITH mutation_map AS (     -- one mutation class per tumour sample
    SELECT
        "case_barcode",
        "sample_barcode_tumor"                        AS "sample_barcode",
        MIN("Variant_Classification")                 AS "mutation_type"
    FROM TCGA_HG19_DATA_V0.TCGA_HG19_DATA_V0.SOMATIC_MUTATION_MC3
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "Hugo_Symbol"       = 'TP53'
    GROUP BY
        "case_barcode",
        "sample_barcode_tumor"
),
expr_mut AS (             -- join RNA-seq expression with mutation map
    SELECT
        e."case_barcode",
        e."sample_barcode",
        m."mutation_type",
        LOG(NULLIF(e."normalized_count",0), 10)       AS log10_expr
    FROM TCGA_HG19_DATA_V0.TCGA_HG19_DATA_V0.RNASEQ_GENE_EXPRESSION_UNC_RSEM e
    JOIN mutation_map m
      ON e."case_barcode"   = m."case_barcode"
     AND e."sample_barcode" = m."sample_barcode"
    WHERE e."project_short_name" = 'TCGA-BRCA'
      AND e."HGNC_gene_symbol"   = 'TP53'
      AND e."normalized_count"   > 0
),
grand_stats AS (
    SELECT
        COUNT(*)            AS N_samples,
        AVG(log10_expr)     AS grand_mean
    FROM expr_mut
),
group_stats AS (
    SELECT
        "mutation_type",
        COUNT(*)            AS n_group,
        AVG(log10_expr)     AS mean_group
    FROM expr_mut
    GROUP BY "mutation_type"
),
ss_between AS (           -- sum of squares between groups
    SELECT
        SUM(n_group * POWER(mean_group - grand_mean, 2))   AS SSB,
        COUNT(*)                                           AS k_groups
    FROM group_stats, grand_stats
),
ss_total AS (             -- total sum of squares
    SELECT
        SUM(POWER(log10_expr - grand_mean, 2))  AS SST
    FROM expr_mut, grand_stats
),
calc AS (                 -- derive df, MS and F
    SELECT
        gs.N_samples                              AS total_samples,
        sb.k_groups                               AS num_mutation_types,
        sb.SSB                                    AS ss_between,
        st.SST                                    AS ss_total,
        st.SST - sb.SSB                           AS ss_within,
        sb.k_groups - 1                           AS df_between,
        gs.N_samples - sb.k_groups                AS df_within
    FROM grand_stats gs
    JOIN ss_between sb   ON 1=1
    JOIN ss_total   st   ON 1=1
)
SELECT
    total_samples,
    num_mutation_types,
    ss_between / NULLIF(df_between,0)             AS mean_square_between,
    ss_within  / NULLIF(df_within,0)              AS mean_square_within,
    (ss_between / NULLIF(df_between,0))
        / NULLIF(ss_within / NULLIF(df_within,0),0) AS f_statistic
FROM calc;