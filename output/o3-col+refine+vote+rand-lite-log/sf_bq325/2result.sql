WITH best_variant_per_gene_study AS (
    /* 1.  For every (gene_id, study_id) keep the variant with the lowest p-value */
    SELECT
        lg."gene_id",
        lg."study_id",
        gw."chrom"  AS "chrom",
        gw."pos"    AS "pos",
        gw."ref"    AS "ref",
        gw."alt"    AS "alt",
        gw."pval"   AS "pval",
        ROW_NUMBER() OVER (
            PARTITION BY lg."gene_id", lg."study_id"
            ORDER BY gw."pval"
        ) AS "rn_in_study"
    FROM   "OPEN_TARGETS_GENETICS_2"."OPEN_TARGETS_GENETICS"."LOCUS2GENE" lg
    JOIN   "OPEN_TARGETS_GENETICS_2"."OPEN_TARGETS_GENETICS"."SA_GWAS"    gw
           ON  lg."study_id" = gw."study_id"
           AND lg."chrom"    = gw."chrom"
           AND lg."pos"      = gw."pos"
           AND lg."ref"      = gw."ref"
           AND lg."alt"      = gw."alt"
),
best_variant_per_gene AS (
    /* 2.  Across all studies pick the strongest association per gene */
    SELECT
        "gene_id",
        "study_id",
        "chrom",
        "pos",
        "ref",
        "alt",
        "pval",
        ROW_NUMBER() OVER (
            PARTITION BY "gene_id"
            ORDER BY "pval"
        ) AS "rn_overall"
    FROM   best_variant_per_gene_study
    WHERE  "rn_in_study" = 1
)

SELECT
    g."gene_name",
    b."gene_id",
    b."study_id",
    b."chrom",
    b."pos",
    b."ref",
    b."alt",
    b."pval"
FROM   best_variant_per_gene b
JOIN   "OPEN_TARGETS_GENETICS_2"."OPEN_TARGETS_GENETICS"."GENES" g
       ON b."gene_id" = g."gene_id"
WHERE  b."rn_overall" = 1
ORDER  BY b."pval" ASC NULLS LAST
LIMIT 10;