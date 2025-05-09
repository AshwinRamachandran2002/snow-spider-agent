WITH per_study_gene AS (             -- best variant per (study, gene)
    SELECT
        "study_id",
        "gene_id",
        MIN("pval") AS "min_pval"
    FROM OPEN_TARGETS_GENETICS_2.OPEN_TARGETS_GENETICS."DISEASE_VARIANT_GENE"
    WHERE "pval" IS NOT NULL
    GROUP BY "study_id", "gene_id"
),
per_gene AS (                        -- best p-value across all studies for each gene
    SELECT
        "gene_id",
        MIN("min_pval") AS "best_pval"
    FROM per_study_gene
    GROUP BY "gene_id"
),
best_variants AS (                   -- concrete variant(s) that achieve that p-value
    SELECT
        d."gene_id",
        d."study_id",
        d."tag_chrom",
        d."tag_pos",
        d."pval"
    FROM OPEN_TARGETS_GENETICS_2.OPEN_TARGETS_GENETICS."DISEASE_VARIANT_GENE" d
    JOIN per_gene pg
      ON  d."gene_id" = pg."gene_id"
     AND d."pval"     = pg."best_pval"
),
unique_gene_variant AS (             -- ensure one row per gene
    SELECT
        g."gene_name",
        b."gene_id",
        b."study_id",
        b."tag_chrom",
        b."tag_pos",
        b."pval",
        ROW_NUMBER() OVER (PARTITION BY b."gene_id" ORDER BY b."pval") AS "rn"
    FROM best_variants b
    LEFT JOIN OPEN_TARGETS_GENETICS_2.OPEN_TARGETS_GENETICS."GENES" g
           ON g."gene_id" = b."gene_id"
)
SELECT
    "gene_name",
    "gene_id",
    "study_id",
    "tag_chrom",
    "tag_pos",
    "pval"
FROM unique_gene_variant
WHERE "rn" = 1                      -- keep one representative variant per gene
ORDER BY "pval" ASC
LIMIT 10;