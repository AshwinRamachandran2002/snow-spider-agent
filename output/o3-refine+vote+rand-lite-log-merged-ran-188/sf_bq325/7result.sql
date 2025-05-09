/* 1)  pick the lowest-p-value variant for every (study_id , gene_id) pair
   2)  keep, for every gene, the single smallest p-value observed across all studies
   3)  return the 10 genes whose best p-values are the smallest overall          */
WITH gene_study_min AS (          -- step-1
    SELECT
        "study_id",
        "gene_id",
        MIN("pval") AS "min_pval"
    FROM  OPEN_TARGETS_GENETICS_2.OPEN_TARGETS_GENETICS."DISEASE_VARIANT_GENE"
    WHERE "pval" IS NOT NULL
    GROUP BY "study_id", "gene_id"
),
best_per_gene AS (               -- step-2
    SELECT
        "gene_id",
        MIN("min_pval") AS "best_pval"
    FROM  gene_study_min
    GROUP BY "gene_id"
),
ranked_genes AS (                -- attach gene symbol & rank globally
    SELECT
        b."gene_id",
        g."gene_name",
        b."best_pval",
        ROW_NUMBER() OVER (ORDER BY b."best_pval" ASC) AS rn
    FROM  best_per_gene b
    LEFT JOIN OPEN_TARGETS_GENETICS_2.OPEN_TARGETS_GENETICS."GENES" g
           ON b."gene_id" = g."gene_id"
)
SELECT
    "gene_id",
    "gene_name",
    "best_pval"       AS "pval"
FROM   ranked_genes
WHERE  rn <= 10
ORDER  BY "best_pval" ASC;