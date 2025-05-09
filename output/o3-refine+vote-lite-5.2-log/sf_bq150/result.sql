WITH expr AS (   -- log10‑transformed TP53 expression for each TCGA‑BRCA sample
    SELECT
        e."sample_barcode"                                         AS sample_barcode,
        LOG(10, e."normalized_count")                              AS log_expr,     -- base‑10 log
        COALESCE(m.mutation_type, 'Wild_Type')                     AS mut_type
    FROM "TCGA_HG19_DATA_V0"."TCGA_HG19_DATA_V0"."RNASEQ_GENE_EXPRESSION_UNC_RSEM" e
    LEFT JOIN (                                                    -- TP53 mutation type per sample
        SELECT
            "sample_barcode_tumor"                                 AS sample_barcode,
            MIN("Variant_Classification")                          AS mutation_type
        FROM "TCGA_HG19_DATA_V0"."TCGA_HG19_DATA_V0"."SOMATIC_MUTATION_MC3"
        WHERE "project_short_name" = 'TCGA-BRCA'
          AND "Hugo_Symbol"       = 'TP53'
        GROUP BY "sample_barcode_tumor"
    ) m
      ON e."sample_barcode" = m.sample_barcode
    WHERE e."project_short_name" = 'TCGA-BRCA'
      AND e."HGNC_gene_symbol"   = 'TP53'
      AND e."normalized_count"   > 0
),
grp AS (           -- counts and means per mutation type
    SELECT
        mut_type,
        COUNT(*)      AS n_j,
        AVG(log_expr) AS mean_j
    FROM expr
    GROUP BY mut_type
),
overall AS (       -- grand totals
    SELECT
        COUNT(*)      AS N,
        AVG(log_expr) AS grand_mean
    FROM expr
),
ssb AS (           -- sum of squares between groups
    SELECT
        SUM(g.n_j * POWER(g.mean_j - o.grand_mean, 2)) AS ssb
    FROM grp g
    CROSS JOIN overall o
),
ssw AS (           -- sum of squares within groups
    SELECT
        SUM(POWER(e.log_expr - g.mean_j, 2)) AS ssw
    FROM expr e
    JOIN grp g ON e.mut_type = g.mut_type
),
df AS (            -- degrees of freedom
    SELECT
        (SELECT COUNT(*) FROM grp) - 1                       AS df_between,
        (SELECT N FROM overall) - (SELECT COUNT(*) FROM grp) AS df_within
),
ms AS (            -- mean squares
    SELECT
        ssb.ssb / df.df_between AS ms_between,
        ssw.ssw / df.df_within  AS ms_within
    FROM ssb, ssw, df
)
SELECT
    (SELECT N FROM overall)           AS total_samples,
    (SELECT COUNT(*) FROM grp)        AS mutation_types,
    ms.ms_between                     AS mean_square_between,
    ms.ms_within                      AS mean_square_within,
    ms.ms_between / ms.ms_within      AS f_statistic
FROM ms;