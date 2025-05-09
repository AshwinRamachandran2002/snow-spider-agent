/* Restrict to extremely significant associations first (p < 1×10⁻⁵⁰) to
   keep the data volume small enough to finish within the time-out.      */
WITH per_study_best AS (
    SELECT
        "gene_id",
        "study_id",
        "tag_chrom",
        "tag_pos",
        "tag_ref",
        "tag_alt",
        "pval"
    FROM
        OPEN_TARGETS_GENETICS_2.OPEN_TARGETS_GENETICS.DISEASE_VARIANT_GENE
    WHERE
        "pval" < 1e-50
    QUALIFY
        ROW_NUMBER() OVER (
            PARTITION BY "gene_id", "study_id"
            ORDER BY "pval" ASC
        ) = 1
),
per_gene_best AS (
    SELECT
        "gene_id",
        "study_id",
        "tag_chrom",
        "tag_pos",
        "tag_ref",
        "tag_alt",
        "pval"
    FROM
        per_study_best
    QUALIFY
        ROW_NUMBER() OVER (
            PARTITION BY "gene_id"
            ORDER BY "pval" ASC
        ) = 1
)
SELECT
    "gene_id",
    "study_id",
    "tag_chrom" || ':' || "tag_pos" || ':' || "tag_ref" || ':' || "tag_alt" AS "variant_id",
    "pval" AS "best_pval"
FROM
    per_gene_best
ORDER BY
    "best_pval" ASC
LIMIT 10;