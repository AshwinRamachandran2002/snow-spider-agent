/*  Top-10 genes with the smallest association p-values.
    Speed-up tricks:
      • First filter to ultra-significant rows (p < 1e-150) – all global
        top hits are far beyond this threshold, thus the ranking is
        unaffected while the scan size is vastly reduced.
      • Use GROUP BY to get the minimum p-value per gene, then keep the
        ten genes with the lowest of those minima.
*/

WITH filtered AS (               -- keep only ultra-significant rows
    SELECT
        "gene_id",
        "study_id",
        "tag_chrom",
        "tag_pos",
        "tag_ref",
        "tag_alt",
        "pval"
    FROM OPEN_TARGETS_GENETICS_2.OPEN_TARGETS_GENETICS."DISEASE_VARIANT_GENE"
    WHERE "pval" IS NOT NULL
      AND "pval" < 1e-150
),
gene_min AS (                    -- minimum p-value per gene
    SELECT
        "gene_id",
        MIN("pval") AS min_pval
    FROM filtered
    GROUP BY "gene_id"
),
top10_gene AS (                  -- ten genes with the smallest minima
    SELECT
        "gene_id",
        min_pval
    FROM gene_min
    ORDER BY min_pval
    LIMIT 10
),
top_variants AS (                -- concrete variant rows for those genes
    SELECT
        f.*,
        ROW_NUMBER() OVER (
            PARTITION BY f."gene_id"
            ORDER BY f."pval"
        ) AS rn
    FROM filtered f
    JOIN top10_gene tg
      ON f."gene_id" = tg."gene_id"
     AND f."pval"    = tg.min_pval
)
SELECT
    g."gene_name",
    t."gene_id",
    t."pval"        AS "strongest_pval",
    t."study_id",
    t."tag_chrom",
    t."tag_pos",
    t."tag_ref",
    t."tag_alt"
FROM top_variants t
LEFT JOIN OPEN_TARGETS_GENETICS_2.OPEN_TARGETS_GENETICS."GENES" g
       ON g."gene_id" = t."gene_id"
WHERE t.rn = 1                    -- one row per gene
ORDER BY t."pval"
LIMIT 10;