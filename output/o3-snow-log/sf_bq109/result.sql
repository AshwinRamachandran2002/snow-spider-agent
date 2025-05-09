WITH filtered AS (
    SELECT c.*
    FROM OPEN_TARGETS_GENETICS_1.GENETICS.VARIANT_DISEASE_COLOC   AS c
    LEFT JOIN OPEN_TARGETS_GENETICS_1.GENETICS.STUDIES            AS s
           ON c."left_study" = s."study_id"
    WHERE c."right_gene_id" = 'ENSG00000169174'
      AND c."coloc_h4" > 0.8
      AND c."coloc_h3" < 0.02
      AND LOWER( COALESCE( s."trait_reported",
                           c."right_phenotype",
                           c."left_study",
                           c."right_study",
                           '' ) ) LIKE '%lesterol levels%'
      AND LOWER(c."right_bio_feature") = 'ipsc'
      AND (
           (c."left_chrom"  = '1' AND c."left_pos"  = 55029009 AND c."left_ref"  = 'C' AND c."left_alt"  = 'T') OR
           (c."right_chrom" = '1' AND c."right_pos" = 55029009 AND c."right_ref" = 'C' AND c."right_alt" = 'T')
          )
),
agg AS (
    SELECT
        AVG("coloc_log2_h4_h3")                         AS avg_log2_h4_h3,
        VAR_POP("coloc_log2_h4_h3")                     AS variance_log2_h4_h3,
        MAX("coloc_log2_h4_h3") - MIN("coloc_log2_h4_h3") AS max_min_diff
    FROM filtered
),
max_study AS (
    SELECT "right_study"
    FROM filtered
    ORDER BY "coloc_log2_h4_h3" DESC NULLS LAST
    LIMIT 1
)
SELECT
    agg.avg_log2_h4_h3,
    agg.variance_log2_h4_h3,
    agg.max_min_diff,
    max_study."right_study" AS qtl_source_right_study
FROM agg
CROSS JOIN max_study;