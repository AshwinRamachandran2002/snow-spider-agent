WITH filtered AS (
    SELECT 
        vc."coloc_log2_h4_h3",
        vc."right_study"
    FROM OPEN_TARGETS_GENETICS_1.GENETICS."VARIANT_DISEASE_COLOC"  vc
    JOIN OPEN_TARGETS_GENETICS_1.GENETICS."STUDIES"                st
          ON vc."left_study" = st."study_id"
    WHERE vc."right_gene_id"      = 'ENSG00000169174'
      AND vc."coloc_h4"           > 0.8
      AND vc."coloc_h3"           < 0.02
      AND vc."right_bio_feature"  = 'IPSC'
      AND vc."left_chrom"         = '1'
      AND vc."left_pos"           = 55029009
      AND vc."left_ref"           = 'C'
      AND vc."left_alt"           = 'T'
      AND st."trait_reported" ILIKE '%lesterol levels%'
), stats AS (
    SELECT
        AVG( "coloc_log2_h4_h3")                                 AS avg_log2_h4_h3,
        VAR_POP("coloc_log2_h4_h3")                              AS var_log2_h4_h3,
        MAX( "coloc_log2_h4_h3") - MIN("coloc_log2_h4_h3")       AS max_min_diff
    FROM filtered
), max_row AS (
    SELECT "right_study"
    FROM filtered
    ORDER BY "coloc_log2_h4_h3" DESC NULLS LAST
    LIMIT 1
)
SELECT 
    s.avg_log2_h4_h3,
    s.var_log2_h4_h3,
    s.max_min_diff,
    m."right_study" AS qtl_source_of_max_log2_h4_h3
FROM stats s
CROSS JOIN max_row m;