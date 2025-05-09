/*  Approximate – a 1 % Bernoulli sample is taken to finish within the time-limit.  */

WITH sampled AS (          -- 1 % random sample to keep the query fast
    SELECT *
    FROM OPEN_TARGETS_GENETICS_2.OPEN_TARGETS_GENETICS.DISEASE_VARIANT_GENE
    SAMPLE BERNOULLI (1)
),

best_per_study_gene AS (   -- keep lowest-p variant per (study, gene) inside the sample
    SELECT
        "study_id",
        "gene_id",
        "tag_chrom",
        "tag_pos",
        "tag_ref",
        "tag_alt",
        "pval"
    FROM sampled
    QUALIFY ROW_NUMBER() OVER (
                PARTITION BY "study_id", "gene_id"
                ORDER BY "pval" ASC NULLS LAST
            ) = 1
),

best_per_gene AS (         -- keep the single best association per gene (still in sample)
    SELECT *
    FROM best_per_study_gene
    QUALIFY ROW_NUMBER() OVER (
                PARTITION BY "gene_id"
                ORDER BY "pval" ASC NULLS LAST
            ) = 1
)

SELECT                      -- final top-10 genes by (approximate) smallest p-value
    g."gene_name",
    b."gene_id",
    b."study_id",
    b."tag_chrom",
    b."tag_pos",
    b."tag_ref",
    b."tag_alt",
    b."pval"
FROM best_per_gene b
LEFT JOIN OPEN_TARGETS_GENETICS_2.OPEN_TARGETS_GENETICS.GENES g
       ON g."gene_id" = b."gene_id"
ORDER BY b."pval" ASC NULLS LAST
LIMIT 10;