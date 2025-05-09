WITH FilteredRecords AS (
    SELECT *
    FROM OPEN_TARGETS_GENETICS_1.GENETICS.VARIANT_DISEASE_COLOC vc
    WHERE
        vc."right_gene_id" = 'ENSG00000169174' AND
        vc."coloc_h4" > 0.8 AND
        vc."coloc_h3" < 0.02 AND
        vc."right_bio_feature" = 'IPSC' AND
        vc."left_chrom" = '1' AND
        vc."left_pos" = 55029009 AND
        vc."left_ref" = 'C' AND
        vc."left_alt" = 'T' AND
        vc."left_study" IN (
            SELECT s."study_id"
            FROM OPEN_TARGETS_GENETICS_1.GENETICS.STUDIES s
            WHERE s."trait_reported" ILIKE '%lesterol levels%'
        )
)
SELECT
    AVG("coloc_log2_h4_h3") AS "average",
    VAR_SAMP("coloc_log2_h4_h3") AS "variance",
    MAX("coloc_log2_h4_h3") - MIN("coloc_log2_h4_h3") AS "max_min_difference",
    (
        SELECT "right_study"
        FROM FilteredRecords
        ORDER BY "coloc_log2_h4_h3" DESC NULLS LAST
        LIMIT 1
    ) AS "QTL_source"
FROM FilteredRecords;