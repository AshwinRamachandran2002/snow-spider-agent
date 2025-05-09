WITH filtered AS (                      -- keep only ultra-significant rows
    SELECT
        "study_id",
        "gene_id",
        "tag_chrom",
        "tag_pos",
        "pval"
    FROM OPEN_TARGETS_GENETICS_2.OPEN_TARGETS_GENETICS.DISEASE_VARIANT_GENE
    WHERE "pval" < 1e-100               -- hard filter to shrink the scan
),  
best_study_gene AS (                    -- best variant per (study, gene)
    SELECT
        "study_id",
        "gene_id",
        "tag_chrom",
        "tag_pos",
        "pval",
        ROW_NUMBER() OVER (
            PARTITION BY "study_id", "gene_id"
            ORDER BY "pval" ASC
        ) AS rn
    FROM filtered
    QUALIFY rn = 1
),  
gene_min AS (                           -- best p-value across all studies
    SELECT
        "gene_id",
        MIN("pval") AS best_gene_pval
    FROM best_study_gene
    GROUP BY "gene_id"
),  
gene_min_info AS (                      -- attach study/variant details
    SELECT
        b."gene_id",
        b."study_id",
        b."tag_chrom",
        b."tag_pos",
        g.best_gene_pval
    FROM gene_min        g
    JOIN best_study_gene b
      ON b."gene_id" = g."gene_id"
     AND b."pval"    = g.best_gene_pval
)  
SELECT
    "gene_id",
    "study_id",
    "tag_chrom",
    "tag_pos",
    best_gene_pval AS "pval"
FROM gene_min_info
ORDER BY "pval" ASC
LIMIT 10;