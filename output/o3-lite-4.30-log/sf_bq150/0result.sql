/*  One‑way ANOVA for log10‑transformed TP53 expression
    across TP53 mutation types in TCGA‑BRCA */

WITH expression AS (   -- log10(TP53 expression) per sample
    SELECT
        "sample_barcode",
        LOG(10 , "normalized_count")            AS "log_expr"
    FROM "TCGA_HG19_DATA_V0"."TCGA_HG19_DATA_V0"."RNASEQ_GENE_EXPRESSION_UNC_RSEM"
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "HGNC_gene_symbol"   = 'TP53'
      AND "normalized_count"  > 0
),
raw_mut AS (          -- all TP53 mutation records
    SELECT
        SUBSTR("sample_barcode_tumor",1,16)     AS "sample_barcode",
        "Variant_Classification"                AS "mutation_type"
    FROM "TCGA_HG19_DATA_V0"."TCGA_HG19_DATA_V0"."SOMATIC_MUTATION_MC3"
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "Hugo_Symbol"       = 'TP53'
),
mutation AS (         -- one mutation type per sample (take first alphabetically)
    SELECT
        "sample_barcode",
        MIN("mutation_type")  AS "mutation_type"
    FROM raw_mut
    GROUP BY "sample_barcode"
),
joined AS (           -- merge expression with mutation class
    SELECT
        e."log_expr",
        m."mutation_type"
    FROM expression e
    JOIN mutation  m ON e."sample_barcode" = m."sample_barcode"
),
group_stats AS (      -- nⱼ and group means
    SELECT
        "mutation_type",
        COUNT(*)              AS n,
        AVG("log_expr")       AS group_mean
    FROM joined
    GROUP BY "mutation_type"
),
overall AS (          -- grand mean
    SELECT AVG("log_expr") AS grand_mean FROM joined
),
ssb AS (              -- Sum of Squares Between groups
    SELECT
        SUM(gs.n * POWER(gs.group_mean - o.grand_mean, 2)) AS SSB
    FROM group_stats gs, overall o
),
ssw AS (              -- Sum of Squares Within groups
    SELECT
        SUM(POWER(j."log_expr" - gs.group_mean, 2)) AS SSW
    FROM joined j
    JOIN group_stats gs ON j."mutation_type" = gs."mutation_type"
),
df AS (               -- degrees of freedom
    SELECT
        (SELECT COUNT(*) FROM group_stats) - 1    AS df_between,
        (SELECT COUNT(*) FROM joined) -
        (SELECT COUNT(*) FROM group_stats)        AS df_within
),
ms AS (               -- mean squares & F‑statistic
    SELECT
        SSB / df_between               AS MSB,
        SSW / df_within                AS MSW,
        (SSB / df_between) / (SSW / df_within) AS F_statistic
    FROM ssb, ssw, df
)
SELECT
    (SELECT COUNT(*) FROM joined)        AS total_samples,
    (SELECT COUNT(*) FROM group_stats)   AS mutation_types,
    ROUND(MSB ,4)                        AS mean_square_between,
    ROUND(MSW ,4)                        AS mean_square_within,
    ROUND(F_statistic ,4)                AS F_statistic
FROM ms;