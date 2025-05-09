/* ----------  Top-10 genes with the strongest associations  ---------- */

WITH gene_best AS (                -- one aggregation pass, uses MIN_BY
    SELECT
        "gene_id",
        MIN("pval")                               AS "best_pval",
        MIN_BY("study_id",  "pval")               AS "study_id",
        MIN_BY("tag_chrom", "pval")               AS "tag_chrom",
        MIN_BY("tag_pos",  "pval")                AS "tag_pos",
        MIN_BY("tag_ref",  "pval")                AS "tag_ref",
        MIN_BY("tag_alt",  "pval")                AS "tag_alt"
    FROM OPEN_TARGETS_GENETICS_2.OPEN_TARGETS_GENETICS."DISEASE_VARIANT_GENE"
    WHERE "pval" IS NOT NULL
    GROUP BY "gene_id"
)

SELECT
    gb."gene_id",
    g."gene_name",
    gb."study_id",
    gb."tag_chrom",
    gb."tag_pos",
    gb."tag_ref",
    gb."tag_alt",
    gb."best_pval"
FROM gene_best gb
LEFT JOIN OPEN_TARGETS_GENETICS_2.OPEN_TARGETS_GENETICS."GENES" g
       ON gb."gene_id" = g."gene_id"
ORDER BY gb."best_pval" ASC
LIMIT 10;