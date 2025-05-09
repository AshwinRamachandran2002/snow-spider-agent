/* 1)  For every gene compute its minimum p-value across all studies.           */
/* 2)  Grab one representative variant that attains that minimum (ties broken   */
/*     deterministically).                                                      */
/* 3)  List the 10 genes whose minima are the smallest overall.                 */

WITH gene_min AS (   -- step-1
    SELECT
        "gene_id",
        MIN("pval") AS min_pval
    FROM OPEN_TARGETS_GENETICS_2.OPEN_TARGETS_GENETICS."DISEASE_VARIANT_GENE"
    WHERE "pval" IS NOT NULL
    GROUP BY "gene_id"
),
best_variant AS (    -- step-2
    SELECT
        d."gene_id",
        d."study_id",
        d."tag_chrom",
        d."tag_pos",
        d."tag_ref",
        d."tag_alt",
        d."pval",
        ROW_NUMBER() OVER (
            PARTITION BY d."gene_id"
            ORDER BY d."pval" ASC, d."study_id"
        ) AS rn
    FROM OPEN_TARGETS_GENETICS_2.OPEN_TARGETS_GENETICS."DISEASE_VARIANT_GENE" d
    JOIN gene_min g
      ON d."gene_id" = g."gene_id"
     AND d."pval"   = g.min_pval
)
SELECT                -- step-3
    "gene_id",
    "study_id",
    "tag_chrom",
    "tag_pos",
    "tag_ref",
    "tag_alt",
    "pval"
FROM best_variant
WHERE rn = 1          -- one row per gene
ORDER BY "pval" ASC NULLS LAST
LIMIT 10;