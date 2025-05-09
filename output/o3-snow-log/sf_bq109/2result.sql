WITH "filtered" AS (
    SELECT
        c."coloc_log2_h4_h3",
        c."right_study"
    FROM OPEN_TARGETS_GENETICS_1.GENETICS."VARIANT_DISEASE_COLOC"        c
    JOIN OPEN_TARGETS_GENETICS_1.GENETICS."STUDIES"                      s
          ON s."study_id" = c."left_study"          -- GWAS side
    WHERE c."right_gene_id"      = 'ENSG00000169174'
      AND c."coloc_h4"           > 0.8
      AND c."coloc_h3"           < 0.02
      AND c."right_bio_feature"  = 'IPSC'
      AND (
              (c."left_chrom"  = '1' AND c."left_pos"  = 55029009 AND c."left_ref" = 'C' AND c."left_alt" = 'T')
           OR (c."right_chrom" = '1' AND c."right_pos" = 55029009 AND c."right_ref" = 'C' AND c."right_alt" = 'T')
          )
      AND s."trait_reported" ILIKE '%lesterol levels%'
),
"stats" AS (
    SELECT
        AVG("coloc_log2_h4_h3")                               AS "avg_log2_h4_h3",
        VAR_POP("coloc_log2_h4_h3")                           AS "var_log2_h4_h3",
        MAX("coloc_log2_h4_h3") - MIN("coloc_log2_h4_h3")     AS "max_min_diff"
    FROM "filtered"
),
"tmax" AS (
    SELECT
        "right_study" AS "qtl_source_max_log2_h4_h3"
    FROM "filtered"
    ORDER BY "coloc_log2_h4_h3" DESC NULLS LAST
    LIMIT 1
)
SELECT
    s."avg_log2_h4_h3",
    s."var_log2_h4_h3",
    s."max_min_diff",
    t."qtl_source_max_log2_h4_h3"
FROM "stats" s,
     "tmax"  t;