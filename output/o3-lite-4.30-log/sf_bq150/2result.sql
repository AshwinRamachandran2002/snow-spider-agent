WITH joined AS (
    SELECT DISTINCT
           e."sample_barcode"                       AS "sample_id",
           LOG(10, e."normalized_count")            AS "log10_expr",
           m."Variant_Classification"               AS "mutation_type"
    FROM "TCGA_HG19_DATA_V0"."TCGA_HG19_DATA_V0"."RNASEQ_GENE_EXPRESSION_UNC_RSEM"  e
    JOIN "TCGA_HG19_DATA_V0"."TCGA_HG19_DATA_V0"."SOMATIC_MUTATION_MC3"            m
      ON e."sample_barcode" = m."sample_barcode_tumor"
    WHERE e."project_short_name" = 'TCGA-BRCA'
      AND m."project_short_name" = 'TCGA-BRCA'
      AND e."HGNC_gene_symbol"   = 'TP53'
      AND m."Hugo_Symbol"        = 'TP53'
      AND e."normalized_count"   > 0
), group_stats AS (
    SELECT
        "mutation_type",
        COUNT(*)                  AS n_group,
        AVG("log10_expr")         AS group_mean
    FROM joined
    GROUP BY "mutation_type"
), grand AS (
    SELECT AVG("log10_expr")      AS grand_mean FROM joined
), ssb AS (
    SELECT
        SUM(n_group * POWER(group_mean - (SELECT grand_mean FROM grand), 2)) AS SSB,
        COUNT(*)                                                             AS k
    FROM group_stats
), ssw AS (
    SELECT
        SUM(POWER(j."log10_expr" - gs.group_mean, 2)) AS SSW
    FROM joined j
    JOIN group_stats gs
      ON j."mutation_type" = gs."mutation_type"
), totals AS (
    SELECT COUNT(*) AS N FROM joined
)
SELECT
    CAST(t.N AS INT)                                           AS total_samples,
    CAST(s.k AS INT)                                           AS mutation_types,
    ROUND(s.SSB / (s.k - 1), 4)                                AS mean_square_between,
    ROUND(w.SSW / (t.N - s.k), 4)                              AS mean_square_within,
    ROUND((s.SSB / (s.k - 1)) / (w.SSW / (t.N - s.k)), 4)      AS F_statistic
FROM ssb s, ssw w, totals t;