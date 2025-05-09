WITH matching_records AS (
    SELECT vd_coloc."coloc_log2_h4_h3", vd_coloc."right_study"
    FROM "OPEN_TARGETS_GENETICS_1"."GENETICS"."VARIANT_DISEASE_COLOC" vd_coloc
    JOIN "OPEN_TARGETS_GENETICS_1"."GENETICS"."STUDIES" studies
    ON vd_coloc."left_study" = studies."study_id"
    WHERE vd_coloc."right_gene_id" = 'ENSG00000169174'
      AND vd_coloc."coloc_h4" > 0.8
      AND vd_coloc."coloc_h3" < 0.02
      AND vd_coloc."right_bio_feature" = 'IPSC'
      AND vd_coloc."left_chrom" = '1'
      AND vd_coloc."left_pos" = 55029009
      AND vd_coloc."left_ref" = 'C'
      AND vd_coloc."left_alt" = 'T'
      AND studies."trait_reported" ILIKE '%lesterol levels%'
)
SELECT 
    ROUND(AVG(mr."coloc_log2_h4_h3"), 4) AS average,
    ROUND(VAR_SAMP(mr."coloc_log2_h4_h3"), 4) AS variance,
    ROUND(MAX(mr."coloc_log2_h4_h3") - MIN(mr."coloc_log2_h4_h3"), 4) AS max_min_difference,
    MAX_BY(mr."right_study", mr."coloc_log2_h4_h3") AS QTL_source
FROM matching_records mr;