WITH ultra_sig AS (           -- keep only ultra-significant rows to speed up
    SELECT
        "gene_id",
        "study_id",
        "tag_chrom",
        "tag_pos",
        "pval"
    FROM OPEN_TARGETS_GENETICS_2.OPEN_TARGETS_GENETICS."DISEASE_VARIANT_GENE"
    WHERE "pval" IS NOT NULL
      AND "pval" <= 1e-100     -- threshold low enough to contain the global top hits
),
best_variant_per_gene_study AS (
    SELECT
        "gene_id",
        "study_id",
        "tag_chrom",
        "tag_pos",
        "pval",
        ROW_NUMBER() OVER (
            PARTITION BY "study_id", "gene_id"
            ORDER BY "pval" ASC
        ) AS rn
    FROM ultra_sig
)

SELECT
    "gene_id",
    "study_id",
    "tag_chrom",
    "tag_pos",
    "pval" AS "best_pval_in_study"
FROM best_variant_per_gene_study
WHERE rn = 1
ORDER BY "best_pval_in_study" ASC
LIMIT 10;