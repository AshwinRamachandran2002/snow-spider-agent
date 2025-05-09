/*  One–way ANOVA (log10‑TP53 expression vs. mutation class)  ––  TCGA‑BRCA  */
WITH expression_data AS (  -- TP53 RNA‑Seq expression (log10)
    SELECT
        "sample_barcode",
        LOG(10, "normalized_count") AS "log10_expr"
    FROM "TCGA_HG19_DATA_V0"."TCGA_HG19_DATA_V0"."RNASEQ_GENE_EXPRESSION_UNC_RSEM"
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "HGNC_gene_symbol"   = 'TP53'
      AND "normalized_count"   > 0               -- avoid log(0)
),
mutation_data AS (         -- TP53 mutation class per tumor sample
    SELECT DISTINCT
        "sample_barcode_tumor"     AS "sample_barcode",
        "Variant_Classification"
    FROM "TCGA_HG19_DATA_V0"."TCGA_HG19_DATA_V0"."SOMATIC_MUTATION_MC3"
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "Hugo_Symbol"        = 'TP53'
),
joined AS (                -- link expression to mutation class; label wild‑type
    SELECT
        e."sample_barcode",
        e."log10_expr",
        COALESCE(m."Variant_Classification", 'Wildtype') AS "mutation_type"
    FROM expression_data e
    LEFT JOIN mutation_data m
           ON e."sample_barcode" = m."sample_barcode"
),
grand_mean AS (            -- overall mean
    SELECT AVG("log10_expr") AS "grand_mean" FROM joined
),
per_group AS (             -- n_j and mean_j for each mutation class
    SELECT
        "mutation_type",
        COUNT(*)          AS "n_j",
        AVG("log10_expr") AS "mean_j"
    FROM joined
    GROUP BY "mutation_type"
),
ssb AS (                    -- sum of squares between groups
    SELECT SUM("n_j" * POWER("mean_j" - g."grand_mean", 2)) AS "SSB"
    FROM per_group, grand_mean g
),
ssw AS (                    -- sum of squares within groups
    SELECT SUM(POWER(j."log10_expr" - p."mean_j", 2)) AS "SSW"
    FROM joined j
    JOIN per_group p USING ("mutation_type")
)
SELECT
    (SELECT COUNT(*) FROM joined)                                               AS "total_samples_N",
    (SELECT COUNT(*) FROM per_group)                                            AS "k_mutation_types",
    (SELECT "SSB" FROM ssb) / ( (SELECT COUNT(*) FROM per_group) - 1 )          AS "MSB",
    (SELECT "SSW" FROM ssw) / ( (SELECT COUNT(*) FROM joined) -
                                (SELECT COUNT(*) FROM per_group) )              AS "MSW",
    ( (SELECT "SSB" FROM ssb) / ( (SELECT COUNT(*) FROM per_group) - 1 ) ) /
    ( (SELECT "SSW" FROM ssw) / ( (SELECT COUNT(*) FROM joined) -
                                  (SELECT COUNT(*) FROM per_group) ) )          AS "F_statistic";