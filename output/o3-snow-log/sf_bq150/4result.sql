WITH expr AS (                       -- log10-transformed TP53 expression in TCGA-BRCA
    SELECT
        "sample_barcode"                                            AS sample_barcode,
        LOG(10, "normalized_count")                                 AS log_expr
    FROM TCGA_HG19_DATA_V0.TCGA_HG19_DATA_V0.RNASEQ_GENE_EXPRESSION_UNC_RSEM
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "HGNC_gene_symbol"  = 'TP53'
      AND "normalized_count"  > 0
), mut AS (                        -- TP53 mutation classifications
    SELECT
        "sample_barcode_tumor"                                      AS sample_barcode,
        "Variant_Classification"                                    AS var_class
    FROM TCGA_HG19_DATA_V0.TCGA_HG19_DATA_V0.SOMATIC_MUTATION_MC3
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "Hugo_Symbol"       = 'TP53'
), mut_one_per_sample AS (        -- single mutation label per sample
    SELECT sample_barcode, MIN(var_class) AS var_class
    FROM mut
    GROUP BY sample_barcode
), expr_mut AS (                  -- merge expression with mutation data
    SELECT
        e.sample_barcode,
        e.log_expr,
        COALESCE(m.var_class, 'Wild_Type') AS mutation_type
    FROM expr e
    LEFT JOIN mut_one_per_sample m
           ON e.sample_barcode = m.sample_barcode
), grp AS (                       -- per-group aggregates
    SELECT
        mutation_type,
        COUNT(*)                AS n,
        SUM(log_expr)           AS sum_x,
        SUM(log_expr * log_expr)AS sum_x2
    FROM expr_mut
    GROUP BY mutation_type
), overall AS (                   -- grand totals
    SELECT
        SUM(n)     AS N,
        SUM(sum_x) AS tot_x,
        SUM(sum_x2)AS tot_x2,
        COUNT(*)   AS k
    FROM grp
), ss AS (                        -- sums of squares
    SELECT
        N,
        k,
        (SELECT SUM(sum_x2 - (sum_x * sum_x) / n) FROM grp)                              AS SSW,
        (SELECT SUM((sum_x * sum_x) / n) FROM grp) - (tot_x * tot_x) / N                 AS SSB
    FROM overall
), anova AS (                     -- mean squares
    SELECT
        N,
        k,
        SSB,
        SSW,
        k - 1                                   AS df_between,
        N - k                                   AS df_within,
        SSB / NULLIF(k - 1, 0)                  AS MS_between,
        SSW / NULLIF(N - k, 0)                  AS MS_within
    FROM ss
)
SELECT
    N                                         AS total_number_of_samples,
    k                                         AS number_of_mutation_types,
    ROUND(MS_between, 4)                      AS mean_square_between_groups,
    ROUND(MS_within , 4)                      AS mean_square_within_groups,
    ROUND(MS_between / MS_within, 4)          AS F_statistic
FROM anova;