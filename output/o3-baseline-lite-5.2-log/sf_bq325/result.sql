WITH per_gene_best_variant AS (
    SELECT
        "study_id",
        "gene_id",
        "tag_chrom"  AS "chrom",
        "tag_pos"    AS "pos",
        "tag_ref"    AS "ref",
        "tag_alt"    AS "alt",
        "pval",
        ROW_NUMBER() OVER (
            PARTITION BY "study_id", "gene_id"
            ORDER BY "pval" ASC NULLS LAST
        ) AS rn
    FROM OPEN_TARGETS_GENETICS_2.OPEN_TARGETS_GENETICS."DISEASE_VARIANT_GENE"
    WHERE "pval" IS NOT NULL
)

SELECT
    v."gene_id",
    g."gene_name",
    v."study_id",
    v."chrom",
    v."pos",
    v."ref",
    v."alt",
    v."pval"
FROM per_gene_best_variant v
LEFT JOIN OPEN_TARGETS_GENETICS_2.OPEN_TARGETS_GENETICS."GENES" g
       ON v."gene_id" = g."gene_id"
WHERE v.rn = 1
ORDER BY v."pval" ASC NULLS LAST
LIMIT 10;