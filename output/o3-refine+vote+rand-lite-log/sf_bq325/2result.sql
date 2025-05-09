WITH  -- 1) get the best (lowest) p‑value for every study‑gene pair in each source table
sa_mt_best AS (
    SELECT
        "gene_id",
        "study_id",
        MIN("pval") AS "min_pval"
    FROM OPEN_TARGETS_GENETICS_2.OPEN_TARGETS_GENETICS.SA_MOLECULAR_TRAIT
    WHERE "pval" IS NOT NULL
      AND "gene_id" IS NOT NULL
    GROUP BY "gene_id", "study_id"
),
dvg_best AS (
    SELECT
        "gene_id",
        "study_id",
        MIN("pval") AS "min_pval"
    FROM OPEN_TARGETS_GENETICS_2.OPEN_TARGETS_GENETICS.DISEASE_VARIANT_GENE
    WHERE "pval" IS NOT NULL
      AND "gene_id" IS NOT NULL
    GROUP BY "gene_id", "study_id"
),

-- 2) combine both sources
all_best AS (
    SELECT * FROM sa_mt_best
    UNION ALL
    SELECT * FROM dvg_best
),

-- 3) for every gene, keep the globally smallest p‑value observed in any study
gene_min AS (
    SELECT
        "gene_id",
        MIN("min_pval") AS "gene_min_pval"
    FROM all_best
    GROUP BY "gene_id"
)

-- 4) return the 10 genes with the strongest evidence
SELECT
    gm."gene_id",
    g."gene_name",
    gm."gene_min_pval" AS "min_pval"
FROM gene_min gm
LEFT JOIN OPEN_TARGETS_GENETICS_2.OPEN_TARGETS_GENETICS.GENES g
       ON g."gene_id" = gm."gene_id"
ORDER BY gm."gene_min_pval" ASC NULLS LAST,
         gm."gene_id"
LIMIT 10;