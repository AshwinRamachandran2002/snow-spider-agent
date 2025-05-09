WITH min_variant_per_gene_study AS (   -- one variant (lowest p-value) per gene × study
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
best_per_gene_study AS (               -- keep only the single best variant
    SELECT
        "gene_id",
        "study_id",
        "tag_chrom",
        "tag_pos",
        "tag_ref",
        "tag_alt",
        "pval"
    FROM min_variant_per_gene_study
    WHERE "rn" = 1
),
ranked_associations AS (               -- rank all gene–variant pairs globally
    SELECT
        g."gene_name",
        b."gene_id",
        b."study_id",
        b."tag_chrom" || ':' || b."tag_pos"::STRING || ':' ||
        b."tag_ref"  || ':' || b."tag_alt"                  AS "variant_id",
        b."pval",
        ROW_NUMBER() OVER (ORDER BY b."pval" ASC NULLS LAST) AS "global_rank"
    FROM best_per_gene_study b
    LEFT JOIN OPEN_TARGETS_GENETICS_2.OPEN_TARGETS_GENETICS."GENES" g
           ON b."gene_id" = g."gene_id"
)
SELECT
    "global_rank",
    "gene_name",
    "gene_id",
    "study_id",
    "variant_id",
    "pval"
FROM ranked_associations
ORDER BY "global_rank"
LIMIT 10;