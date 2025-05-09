WITH tp53_expr AS (   -- TP53 expression (log10) for BRCA
    SELECT
        "sample_barcode",
        LOG(10, "normalized_count")             AS log_expr      -- base-10 log
    FROM  "TCGA_HG19_DATA_V0"."TCGA_HG19_DATA_V0"."RNASEQ_GENE_EXPRESSION_UNC_RSEM"
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "HGNC_gene_symbol"   = 'TP53'
      AND "normalized_count"   > 0
),
tp53_mut AS (         -- TP53 mutation class per sample
    SELECT
        "sample_barcode_tumor"                  AS sample_barcode,
        MIN("Variant_Classification")           AS variant_class
    FROM  "TCGA_HG19_DATA_V0"."TCGA_HG19_DATA_V0"."SOMATIC_MUTATION_MC3"
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "Hugo_Symbol"        = 'TP53'
    GROUP BY "sample_barcode_tumor"
),
merged AS (           -- combine expression with mutation status
    SELECT
        e."sample_barcode",
        COALESCE(m.variant_class, 'WT')         AS mutation_type,
        e.log_expr
    FROM tp53_expr e
    LEFT JOIN tp53_mut m
           ON e."sample_barcode" = m.sample_barcode
),
stats_per_group AS (  -- per-group counts, means, variances
    SELECT
        mutation_type,
        COUNT(*)                           AS n_samples,
        AVG(log_expr)                      AS mean_expr,
        COALESCE(VAR_SAMP(log_expr), 0)    AS var_expr
    FROM merged
    GROUP BY mutation_type
),
overall AS (          -- totals across all samples
    SELECT
        COUNT(*)      AS total_samples,
        AVG(log_expr) AS grand_mean
    FROM merged
),
ssb AS (              -- Sum of Squares Between
    SELECT
        SUM(n_samples * POWER(mean_expr - (SELECT grand_mean FROM overall), 2))
        AS ss_between
    FROM stats_per_group
),
ssw AS (              -- Sum of Squares Within
    SELECT
        SUM( (n_samples - 1) * var_expr ) AS ss_within
    FROM stats_per_group
)
SELECT
    (SELECT total_samples      FROM overall)                            AS total_samples,
    (SELECT COUNT(*)           FROM stats_per_group)                    AS num_mutation_types,
    (SELECT ss_between FROM ssb) /
        ( (SELECT COUNT(*) FROM stats_per_group) - 1 )                  AS ms_between,
    (SELECT ss_within  FROM ssw) /
        ( (SELECT total_samples FROM overall) -
          (SELECT COUNT(*)      FROM stats_per_group) )                 AS ms_within,
    ( (SELECT ss_between FROM ssb) /
        ( (SELECT COUNT(*) FROM stats_per_group) - 1 ) )
      /
    ( (SELECT ss_within  FROM ssw) /
        ( (SELECT total_samples FROM overall) -
          (SELECT COUNT(*)      FROM stats_per_group) ) )               AS f_statistic
;