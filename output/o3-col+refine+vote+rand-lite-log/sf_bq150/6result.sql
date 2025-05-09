/*  One-way ANOVA of log10-transformed TP53 expression vs. TP53 mutation class
    in TCGA-BRCA samples                                          */

WITH expr AS (   -- TP53 expression (keep positive values only)
    SELECT  "sample_barcode"            AS "sample",
            LOG(10, "normalized_count") AS "log10_expr"
    FROM    TCGA_HG19_DATA_V0.TCGA_HG19_DATA_V0."RNASEQ_GENE_EXPRESSION_UNC_RSEM"
    WHERE   "project_short_name" = 'TCGA-BRCA'
      AND   "HGNC_gene_symbol"  ILIKE 'TP53'
      AND   "normalized_count"  > 0
),
mut AS (         -- TP53 mutation calls
    SELECT  "sample_barcode_tumor" AS "sample",
            "Variant_Classification" AS "mut_class"
    FROM    TCGA_HG19_DATA_V0.TCGA_HG19_DATA_V0."SOMATIC_MUTATION_MC3"
    WHERE   "project_short_name" = 'TCGA-BRCA'
      AND   "Hugo_Symbol"        = 'TP53'
),
joined AS (      -- combine expression with mutation status (default = WT)
    SELECT  e."sample",
            COALESCE(m."mut_class", 'WT') AS "mutation_type",
            e."log10_expr"
    FROM    expr e
    LEFT JOIN mut m USING ("sample")
),
grand_stats AS ( -- grand totals
    SELECT  COUNT(*) AS N,
            AVG("log10_expr") AS grand_mean
    FROM    joined
),
grp_stats AS (   -- per-mutation-type statistics
    SELECT  "mutation_type",
            COUNT(*)                     AS n_j,
            AVG("log10_expr")            AS mean_j,
            VAR_POP("log10_expr")        AS var_pop_j           -- population variance
    FROM    joined
    GROUP BY "mutation_type"
),
ss_parts AS (    -- sum-of-squares components
    SELECT  SUM(gs.n_j * POWER(gs.mean_j - g.grand_mean, 2))      AS ss_between,
            SUM(gs.var_pop_j * gs.n_j)                            AS ss_within,
            SUM(gs.n_j)                                           AS total_samples,
            COUNT(*)                                              AS k
    FROM    grp_stats gs
    CROSS JOIN grand_stats g
)
SELECT  total_samples                                        AS "total_samples",
        k                                                    AS "n_mutation_types",
        ss_between / (k - 1)                                 AS "ms_between",
        ss_within  / (total_samples - k)                     AS "ms_within",
        (ss_between / (k - 1)) / NULLIF(ss_within / (total_samples - k),0)
                                                             AS "f_statistic"
FROM    ss_parts;