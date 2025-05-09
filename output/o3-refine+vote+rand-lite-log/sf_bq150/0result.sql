WITH expr AS (   -- TP53 expression (log10 transformed) in TCGA‑BRCA
    SELECT
        "sample_barcode",
        LOG("normalized_count", 10)                 AS log_expr      -- base‑10 log
    FROM TCGA_HG19_DATA_V0.TCGA_HG19_DATA_V0."RNASEQ_GENE_EXPRESSION_UNC_RSEM"
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "HGNC_gene_symbol"  = 'TP53'
      AND "normalized_count"  > 0
),
mut_raw AS (      -- every TP53 mutation record in TCGA‑BRCA
    SELECT
        "sample_barcode_tumor"                      AS sample_barcode,
        "Variant_Classification"                    AS mutation_type
    FROM TCGA_HG19_DATA_V0.TCGA_HG19_DATA_V0."SOMATIC_MUTATION_MC3"
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "Hugo_Symbol"        = 'TP53'
),
mut AS (          -- one mutation type per sample (if >1 pick arbitrarily)
    SELECT
        sample_barcode,
        MIN(mutation_type)                          AS mutation_type
    FROM mut_raw
    GROUP BY sample_barcode
),
combined AS (     -- join expression with mutation type (wild‑type if none)
    SELECT
        e."sample_barcode",
        COALESCE(m.mutation_type, 'Wild_Type')      AS mutation_type,
        e.log_expr
    FROM expr e
    LEFT JOIN mut m
      ON e."sample_barcode" = m.sample_barcode
),
group_stats AS (  -- nₖ and mean per mutation group
    SELECT
        mutation_type,
        COUNT(*)                                    AS n_j,
        AVG(log_expr)                               AS mean_j
    FROM combined
    GROUP BY mutation_type
),
grand AS (        -- overall N and grand mean
    SELECT
        COUNT(*)                                    AS N,
        AVG(log_expr)                               AS grand_mean
    FROM combined
),
ssb AS (          -- sum‑of‑squares between groups
    SELECT
        SUM(gs.n_j * POWER(gs.mean_j - g.grand_mean, 2)) AS ss_between
    FROM group_stats gs
    CROSS JOIN grand g
),
ssw AS (          -- sum‑of‑squares within groups
    SELECT
        SUM(POWER(c.log_expr - gs.mean_j, 2))            AS ss_within
    FROM combined     c
    JOIN group_stats  gs
      ON c.mutation_type = gs.mutation_type
),
df AS (           -- degrees of freedom
    SELECT
        (SELECT COUNT(*) FROM group_stats) - 1                           AS df_between,
        (SELECT N FROM grand) - (SELECT COUNT(*) FROM group_stats)       AS df_within
)
SELECT
    g.N                                                                 AS "total_samples",
    (SELECT COUNT(*) FROM group_stats)                                   AS "number_of_mutation_types",
    s_b.ss_between / df.df_between                                       AS "mean_square_between",
    s_w.ss_within  / df.df_within                                        AS "mean_square_within",
    (s_b.ss_between / df.df_between) / (s_w.ss_within / df.df_within)    AS "F_statistic"
FROM grand  g
CROSS JOIN ssb s_b
CROSS JOIN ssw s_w
CROSS JOIN df;