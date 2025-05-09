/* 1) get the best (smallest) p‑value per gene in each study              */
/* 2) keep the 10 smallest of those gene–study p‑values overall           */
/* 3) fetch the corresponding variant details for those 10 rows           */
WITH gene_study_min AS (          -- step 1
    SELECT
        "study_id",
        "gene_id",
        MIN("pval") AS min_pval
    FROM
        "OPEN_TARGETS_GENETICS_2"."OPEN_TARGETS_GENETICS"."DISEASE_VARIANT_GENE"
    WHERE
        "pval" IS NOT NULL
    GROUP BY
        "study_id",
        "gene_id"
),
top10 AS (                        -- step 2
    SELECT
        "study_id",
        "gene_id",
        min_pval
    FROM
        gene_study_min
    ORDER BY
        min_pval ASC
    LIMIT 10
),
variant_details AS (              -- step 3
    SELECT
        dvg."gene_id",
        dvg."study_id",
        dvg."tag_chrom" AS "chrom",
        dvg."tag_pos"   AS "pos",
        dvg."tag_ref"   AS "ref",
        dvg."tag_alt"   AS "alt",
        dvg."pval"
    FROM
        "OPEN_TARGETS_GENETICS_2"."OPEN_TARGETS_GENETICS"."DISEASE_VARIANT_GENE" dvg
        JOIN top10 t
          ON  dvg."study_id" = t."study_id"
          AND dvg."gene_id"  = t."gene_id"
          AND dvg."pval"     = t.min_pval
)
SELECT
    "gene_id",
    "study_id",
    "chrom",
    "pos",
    "ref",
    "alt",
    "pval"
FROM
    variant_details
ORDER BY
    "pval" ASC,
    "gene_id",
    "study_id";