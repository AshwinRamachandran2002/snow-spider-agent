/*  Top‑10 genes with the strongest variant associations across all studies  */
WITH combined AS (  --------------------------------------------------------------------
    /* pool variant‑level p‑values that have an associated gene_id                         */
    SELECT
        "study_id",
        "gene_id",
        "chrom",
        "pos",
        "ref",
        "alt",
        "pval"
    FROM "OPEN_TARGETS_GENETICS_2"."OPEN_TARGETS_GENETICS"."SA_MOLECULAR_TRAIT"
    WHERE "pval" IS NOT NULL

    UNION ALL

    SELECT
        "study_id",
        "gene_id",
        "tag_chrom" AS "chrom",
        "tag_pos"   AS "pos",
        "tag_ref"   AS "ref",
        "tag_alt"   AS "alt",
        "pval"
    FROM "OPEN_TARGETS_GENETICS_2"."OPEN_TARGETS_GENETICS"."DISEASE_VARIANT_GENE"
    WHERE "pval" IS NOT NULL
),
gene_study_min AS ( ---------------------------------------------------------------------
    /* within every (study, gene) keep the single most‑significant variant                */
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY "study_id", "gene_id"
                           ORDER BY "pval") AS rn_study
    FROM combined
),
gene_best AS (      ----------------------------------------------------------------------
    /* retain only those “best‑within‑study” rows                                         */
    SELECT
        "study_id",
        "gene_id",
        "chrom",
        "pos",
        "ref",
        "alt",
        "pval"
    FROM gene_study_min
    WHERE rn_study = 1
),
ranked_genes AS (   ----------------------------------------------------------------------
    /* for every gene, keep its single strongest association across all studies           */
    SELECT
        "gene_id",
        "study_id",
        CONCAT("chrom", ':', "pos", ':', "ref", ':', "alt") AS variant_id,
        "pval",
        ROW_NUMBER() OVER (PARTITION BY "gene_id"
                           ORDER BY "pval") AS rn_gene
    FROM gene_best
)
SELECT  ----------------------------------------------------------------------------------
    COALESCE(g."gene_name", rg."gene_id")                     AS gene_symbol,
    rg.variant_id                                             AS variant_id,
    rg."study_id"                                             AS study,
    CAST(ROUND(rg."pval", 4) AS FLOAT)                        AS p_value
FROM   ranked_genes rg
LEFT   JOIN "OPEN_TARGETS_GENETICS_2"."OPEN_TARGETS_GENETICS"."GENES" g
       ON rg."gene_id" = g."gene_id"
WHERE  rg.rn_gene = 1
ORDER  BY rg."pval" ASC, gene_symbol
LIMIT 10;