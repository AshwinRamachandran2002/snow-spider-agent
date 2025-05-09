/*  Top-10 genes with the smallest p-values across all studies
    ----------------------------------------------------------
    1.  For every gene, find its minimum p-value (gene_min).
    2.  Fetch the variant(s) that achieve that minimum, then keep one
        representative row per gene (gene_best_variant, rn = 1).
    3.  Return the ten genes with the strongest evidence.
*/

WITH gene_min AS (                      -- step 1
    SELECT
        "gene_id",
        MIN("pval") AS "min_pval"
    FROM OPEN_TARGETS_GENETICS_2.OPEN_TARGETS_GENETICS."DISEASE_VARIANT_GENE"
    WHERE "pval" IS NOT NULL
    GROUP BY "gene_id"
),

gene_best_variant AS (                  -- step 2
    SELECT
        dvg."gene_id",
        dvg."study_id",
        dvg."tag_chrom",
        dvg."tag_pos",
        dvg."pval",
        ROW_NUMBER() OVER (
            PARTITION BY dvg."gene_id"
            ORDER BY dvg."pval" ASC, dvg."study_id"
        ) AS rn
    FROM OPEN_TARGETS_GENETICS_2.OPEN_TARGETS_GENETICS."DISEASE_VARIANT_GENE" dvg
    INNER JOIN gene_min gm
            ON dvg."gene_id" = gm."gene_id"
           AND dvg."pval"    = gm."min_pval"
)

SELECT                                  -- step 3
    "gene_id",
    "study_id",
    "tag_chrom",
    "tag_pos",
    "pval"
FROM gene_best_variant
WHERE rn = 1                            -- one row per gene
ORDER BY "pval" ASC
LIMIT 10;