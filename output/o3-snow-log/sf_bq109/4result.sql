WITH filter_data AS (
    SELECT
        "coloc_log2_h4_h3",
        "right_study"
    FROM OPEN_TARGETS_GENETICS_1.GENETICS.VARIANT_DISEASE_COLOC
    WHERE
        "right_gene_id" = 'ENSG00000169174'
        AND "coloc_h4"  > 0.8
        AND "coloc_h3"  < 0.02
        AND (
                ("left_chrom"  = '1' AND "left_pos"  = 55029009 AND "left_ref"  = 'C' AND "left_alt"  = 'T')
             OR ("right_chrom" = '1' AND "right_pos" = 55029009 AND "right_ref" = 'C' AND "right_alt" = 'T')
            )
        AND "right_bio_feature" = 'IPSC'
        AND LOWER(COALESCE("right_phenotype", '')) LIKE '%lesterol levels%'
)
SELECT
    AVG("coloc_log2_h4_h3")                                       AS "average_log2_h4_h3",
    VAR_SAMP("coloc_log2_h4_h3")                                  AS "variance_log2_h4_h3",
    MAX("coloc_log2_h4_h3") - MIN("coloc_log2_h4_h3")             AS "max_min_difference",
    (
        SELECT "right_study"
        FROM filter_data
        ORDER BY "coloc_log2_h4_h3" DESC NULLS LAST
        LIMIT 1
    )                                                             AS "qtl_source_of_max"
FROM filter_data;