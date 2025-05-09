WITH expr AS (   -- TP53 expression (log10‑transformed) in TCGA‑BRCA
    SELECT
        "sample_barcode"                                              AS sample_id ,
        LOG(10 , "normalized_count")                                  AS log_expr      -- base‑10 log
    FROM TCGA_HG19_DATA_V0.TCGA_HG19_DATA_V0."RNASEQ_GENE_EXPRESSION_UNC_RSEM"
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "HGNC_gene_symbol"  = 'TP53'
      AND "normalized_count"  > 0
),
mut AS (         -- per‑sample TP53 mutation type (if any)
    SELECT
        "sample_barcode_tumor"                                        AS sample_id ,
        MIN("Variant_Classification")                                 AS mutation_type
    FROM TCGA_HG19_DATA_V0.TCGA_HG19_DATA_V0."SOMATIC_MUTATION_MC3"
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "Hugo_Symbol"       = 'TP53'
    GROUP BY "sample_barcode_tumor"
),
combined AS (    -- merge expression with mutation status
    SELECT
        e.sample_id ,
        e.log_expr ,
        COALESCE(m.mutation_type , 'Wild_Type')                       AS mutation_type
    FROM expr e
    LEFT JOIN mut m  ON e.sample_id = m.sample_id
),
stats AS (       -- overall counts and grand mean
    SELECT
        COUNT(*)                         AS total_n ,
        COUNT(DISTINCT mutation_type)    AS k_groups ,
        AVG(log_expr)                    AS grand_mean
    FROM combined
),
grp AS (         -- group‑level counts and means
    SELECT
        mutation_type ,
        COUNT(*)      AS n_j ,
        AVG(log_expr) AS mean_j
    FROM combined
    GROUP BY mutation_type
),
ssb AS (         -- sum of squares between groups
    SELECT SUM( n_j * POWER(mean_j - (SELECT grand_mean FROM stats), 2) )  AS ss_between
    FROM grp
),
ssw AS (         -- sum of squares within groups
    SELECT SUM( POWER(c.log_expr - g.mean_j, 2) )                          AS ss_within
    FROM combined c
    JOIN grp g  ON c.mutation_type = g.mutation_type
),
anova AS (       -- mean squares & F statistic
    SELECT
        s.total_n                                                AS total_samples ,
        s.k_groups                                               AS mutation_types ,
        ssb.ss_between                                           AS ssb ,
        ssw.ss_within                                            AS ssw ,
        ssb.ss_between / (s.k_groups - 1)                        AS ms_between ,
        ssw.ss_within / (s.total_n   - s.k_groups)               AS ms_within ,
        ( ssb.ss_between / (s.k_groups - 1) )
        / ( ssw.ss_within / (s.total_n - s.k_groups) )           AS f_statistic
    FROM stats s , ssb , ssw
)
SELECT
    total_samples ,
    mutation_types ,
    ROUND(ms_between , 6)  AS mean_square_between ,
    ROUND(ms_within  , 6)  AS mean_square_within ,
    ROUND(f_statistic, 6)  AS f_statistic
FROM anova;