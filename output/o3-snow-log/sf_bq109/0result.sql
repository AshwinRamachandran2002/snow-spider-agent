WITH "filtered" AS (
    SELECT *
    FROM OPEN_TARGETS_GENETICS_1.GENETICS.VARIANT_DISEASE_COLOC
    WHERE "right_gene_id" = 'ENSG00000169174'
      AND "coloc_h4" > 0.8
      AND "coloc_h3" < 0.02
      AND LOWER(COALESCE("right_phenotype", '')) LIKE '%lesterol levels%'
      AND "right_bio_feature" = 'IPSC'
      AND "right_chrom" = '1'
      AND "right_pos"  = 55029009
      AND "right_ref"  = 'C'
      AND "right_alt"  = 'T'
)
SELECT
    AVG("coloc_log2_h4_h3")                                 AS "average_log2_h4_h3",
    VARIANCE("coloc_log2_h4_h3")                            AS "variance_log2_h4_h3",
    MAX("coloc_log2_h4_h3") - MIN("coloc_log2_h4_h3")       AS "max_min_difference",
    (
        SELECT "right_study"
        FROM "filtered"
        ORDER BY "coloc_log2_h4_h3" DESC NULLS LAST
        LIMIT 1
    )                                                       AS "right_study_of_max_log2_h4_h3"
FROM "filtered";