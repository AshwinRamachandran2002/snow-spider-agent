WITH "filtered" AS (
    SELECT
        "coloc_log2_h4_h3",
        "right_study"
    FROM OPEN_TARGETS_GENETICS_1.GENETICS."VARIANT_DISEASE_COLOC"
    WHERE "right_gene_id" = 'ENSG00000169174'
      AND "coloc_h4" > 0.8
      AND "coloc_h3" < 0.02
      AND "right_phenotype" ILIKE '%lesterol levels%'
      AND "right_bio_feature" = 'IPSC'
      AND (
            ("left_chrom"  || '_' || TO_VARCHAR("left_pos")  || '_' || "left_ref"  || '_' || "left_alt")  = '1_55029009_C_T'
         OR ("right_chrom" || '_' || TO_VARCHAR("right_pos") || '_' || "right_ref" || '_' || "right_alt") = '1_55029009_C_T'
          )
),
"stats" AS (
    SELECT
        AVG("coloc_log2_h4_h3")      AS "avg_log2_h4_h3",
        VAR_SAMP("coloc_log2_h4_h3") AS "var_log2_h4_h3",
        (MAX("coloc_log2_h4_h3") -
         MIN("coloc_log2_h4_h3"))    AS "range_log2_h4_h3"
    FROM "filtered"
)
SELECT
    s."avg_log2_h4_h3",
    s."var_log2_h4_h3",
    s."range_log2_h4_h3",
    m."right_study" AS "right_study_of_max_log2_h4_h3"
FROM "stats" s
LEFT JOIN (
    SELECT "right_study"
    FROM "filtered"
    ORDER BY "coloc_log2_h4_h3" DESC NULLS LAST
    LIMIT 1
) m ON 1 = 1;