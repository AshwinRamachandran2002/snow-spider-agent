/* Top-10 genes with the strongest variant associations */
WITH
/* ─────────────────────────────────────────────────────────────── */
/* 1)  Best (lowest-p) variant per (gene,study)  –  Molecular-trait */
sa_best AS (
    SELECT
        "gene_id",
        "study_id",
        "chrom",
        "pos",
        "ref",
        "alt",
        "pval"
    FROM (
        SELECT
            "gene_id",
            "study_id",
            "chrom",
            "pos",
            "ref",
            "alt",
            "pval",
            ROW_NUMBER() OVER (PARTITION BY "gene_id","study_id"
                               ORDER BY "pval") AS rn
        FROM OPEN_TARGETS_GENETICS_2.OPEN_TARGETS_GENETICS."SA_MOLECULAR_TRAIT"
        /* light pre-filter to speed up scan; keeps extremely significant rows */
        WHERE "pval" < 1e-6
    )
    WHERE rn = 1
),

/* 2)  Best (lowest-p) variant per (gene,study)  –  Disease GWAS/QTL */
dvg_best AS (
    SELECT
        "gene_id",
        "study_id",
        "lead_chrom" AS "chrom",
        "lead_pos"   AS "pos",
        "lead_ref"   AS "ref",
        "lead_alt"   AS "alt",
        "pval"
    FROM (
        SELECT
            "gene_id",
            "study_id",
            "lead_chrom",
            "lead_pos",
            "lead_ref",
            "lead_alt",
            "pval",
            ROW_NUMBER() OVER (PARTITION BY "gene_id","study_id"
                               ORDER BY "pval") AS rn
        FROM OPEN_TARGETS_GENETICS_2.OPEN_TARGETS_GENETICS."DISEASE_VARIANT_GENE"
        WHERE "pval" IS NOT NULL
          AND "pval" < 1e-6          -- same pre-filter
    )
    WHERE rn = 1
),

/* 3)  Merge both sources */
combined AS (
    SELECT * FROM sa_best
    UNION ALL
    SELECT * FROM dvg_best
),

/* 4)  Single strongest signal per gene across ALL studies/sources */
gene_best AS (
    SELECT
        "gene_id",
        "study_id",
        "chrom",
        "pos",
        "ref",
        "alt",
        "pval",
        ROW_NUMBER() OVER (PARTITION BY "gene_id"
                           ORDER BY "pval") AS rn_gene
    FROM combined
)

/* 5)  Return global top-10 genes */
SELECT
    "gene_id",
    "study_id",
    "chrom",
    "pos",
    "ref",
    "alt",
    "pval"
FROM gene_best
WHERE rn_gene = 1
ORDER BY "pval"
LIMIT 10;