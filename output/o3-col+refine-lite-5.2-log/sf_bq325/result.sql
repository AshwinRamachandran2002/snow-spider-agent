WITH ranked_per_study AS (
    SELECT
        "gene_id",
        "study_id",
        "tag_chrom",
        "tag_pos",
        "tag_ref",
        "tag_alt",
        "pval",
        ROW_NUMBER() OVER (
            PARTITION BY "gene_id", "study_id"
            ORDER BY "pval" ASC, "tag_chrom", "tag_pos"
        ) AS "rn"
    FROM OPEN_TARGETS_GENETICS_2.OPEN_TARGETS_GENETICS."DISEASE_VARIANT_GENE"
    WHERE "pval" IS NOT NULL
),

best_per_gene_study AS (
    -- keep the single lowest‑p variant per gene per study
    SELECT *
    FROM ranked_per_study
    WHERE "rn" = 1
),

rank_overall AS (
    SELECT
        "gene_id",
        "study_id",
        "tag_chrom",
        "tag_pos",
        "tag_ref",
        "tag_alt",
        "pval",
        ROW_NUMBER() OVER (ORDER BY "pval" ASC, "gene_id") AS "overall_rank"
    FROM best_per_gene_study
)

SELECT
    "gene_id",
    "study_id",
    "tag_chrom",
    "tag_pos",
    "tag_ref",
    "tag_alt",
    "pval"
FROM rank_overall
WHERE "overall_rank" <= 10
ORDER BY "pval" ASC, "gene_id";