WITH expr AS (   -- TP53 log10-expression in TCGA-BRCA tumour samples
    SELECT
        "sample_barcode"                         AS "sample_barcode",
        LOG(10, "normalized_count")              AS "log_expr"
    FROM TCGA_HG19_DATA_V0.TCGA_HG19_DATA_V0.RNASEQ_GENE_EXPRESSION_UNC_RSEM
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "HGNC_gene_symbol"   = 'TP53'
      AND "normalized_count"   > 0
      AND "sample_barcode" ILIKE '%-01%'         -- primary tumour samples
),
mut_raw AS (     -- all TP53 mutation calls
    SELECT
        "sample_barcode_tumor"                   AS "sample_barcode",
        "Variant_Classification"                 AS "variant_class"
    FROM TCGA_HG19_DATA_V0.TCGA_HG19_DATA_V0.SOMATIC_MUTATION_MC3
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "Hugo_Symbol"       = 'TP53'
),
mut AS (         -- one mutation type per sample (lexicographically first)
    SELECT
        "sample_barcode",
        MIN("variant_class")                     AS "mutation_type"
    FROM mut_raw
    GROUP BY "sample_barcode"
),
combined AS (    -- merge expression with mutation data
    SELECT
        e."sample_barcode",
        COALESCE(m."mutation_type", 'Wildtype')  AS "mutation_type",
        e."log_expr"
    FROM expr e
    LEFT JOIN mut m USING ("sample_barcode")
),
group_stats AS ( -- per-mutation-type counts and means
    SELECT
        "mutation_type",
        COUNT(*)                 AS n_j,
        AVG("log_expr")          AS mean_j
    FROM combined
    GROUP BY "mutation_type"
),
grand AS (       -- overall sample count and mean
    SELECT
        COUNT(*)                 AS N,
        AVG("log_expr")          AS grand_mean
    FROM combined
),
ssb AS (         -- sum of squares between groups
    SELECT
        SUM(gs.n_j * POWER(gs.mean_j - g.grand_mean, 2)) AS ssb
    FROM group_stats gs
    CROSS JOIN grand g
),
ssw AS (         -- sum of squares within groups
    SELECT
        SUM(POWER(c."log_expr" - gs.mean_j, 2))          AS ssw
    FROM combined c
    JOIN group_stats gs USING ("mutation_type")
),
final AS (       -- assemble ANOVA components
    SELECT
        g.N                          AS N,
        (SELECT COUNT(*) FROM group_stats) AS k,
        ssb.ssb,
        ssw.ssw,
        (SELECT COUNT(*) FROM group_stats) - 1       AS df_between,
        g.N - (SELECT COUNT(*) FROM group_stats)     AS df_within
    FROM grand g, ssb, ssw
),
anova AS (
    SELECT
        N,
        k,
        ssb / df_between                                AS msb,
        ssw / df_within                                 AS msw,
        (ssb / df_between) / (ssw / df_within)          AS f_statistic
    FROM final
)
SELECT
    N                        AS total_samples,
    k                        AS mutation_types,
    ROUND(msb, 4)            AS mean_square_between,
    ROUND(msw, 4)            AS mean_square_within,
    ROUND(f_statistic, 4)    AS f_statistic
FROM anova;