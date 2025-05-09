WITH expr AS (  -- 1. TP53 log10 expression matched to mutation class
    SELECT
        e."sample_barcode",
        LOG(10, e."normalized_count")           AS log10_expr,
        m."Variant_Classification"              AS mutation_class
    FROM "TCGA_HG19_DATA_V0"."TCGA_HG19_DATA_V0"."RNASEQ_GENE_EXPRESSION_UNC_RSEM"  e
    JOIN "TCGA_HG19_DATA_V0"."TCGA_HG19_DATA_V0"."SOMATIC_MUTATION_MC3"            m
      ON e."sample_barcode" = m."sample_barcode_tumor"
    WHERE e."project_short_name" = 'TCGA-BRCA'
      AND m."project_short_name" = 'TCGA-BRCA'
      AND e."HGNC_gene_symbol"   = 'TP53'
      AND m."Hugo_Symbol"        = 'TP53'
      AND e."normalized_count"   > 0
), overall AS (  -- 2. grand totals
    SELECT
        COUNT(*)                    AS N_total,
        SUM(log10_expr)             AS sum_x,
        SUM(POWER(log10_expr, 2))   AS sum_x2
    FROM expr
), by_group AS ( -- 3. per-mutation-class aggregates
    SELECT
        mutation_class,
        COUNT(*)                    AS n_j,
        SUM(log10_expr)             AS sum_x,
        SUM(POWER(log10_expr, 2))   AS sum_x2
    FROM expr
    GROUP BY mutation_class
), stats AS (    -- 4. compute SSB and SSW
    SELECT
        MAX(o.N_total)                                              AS N_total,
        COUNT(*)                                                    AS k,
        SUM( bg.n_j * POWER( (bg.sum_x / bg.n_j) - (o.sum_x / o.N_total), 2) ) AS SSB,
        SUM( bg.sum_x2 - bg.n_j * POWER(bg.sum_x / bg.n_j, 2) )               AS SSW
    FROM by_group bg
    CROSS JOIN overall o
), anova AS (    -- 5. mean squares and F statistic
    SELECT
        N_total,
        k,
        SSB,
        SSW,
        SSB / NULLIF(k - 1,       0)                         AS MSB,
        SSW / NULLIF(N_total - k, 0)                         AS MSW,
        (SSB / NULLIF(k - 1, 0)) /
        NULLIF(SSW / NULLIF(N_total - k, 0), 0)              AS F_statistic
    FROM stats
)
SELECT
    N_total       AS "total_samples",
    k             AS "mutation_types",
    MSB           AS "mean_square_between",
    MSW           AS "mean_square_within",
    F_statistic   AS "F_statistic"
FROM anova;