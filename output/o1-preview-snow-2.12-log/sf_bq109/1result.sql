WITH filtered_data AS (
    SELECT 
        c."coloc_log2_h4_h3", 
        c."right_study"
    FROM "OPEN_TARGETS_GENETICS_1"."GENETICS"."VARIANT_DISEASE_COLOC" c
    JOIN "OPEN_TARGETS_GENETICS_1"."GENETICS"."STUDIES" s
        ON c."left_study" = s."study_id"
    WHERE c."right_gene_id" = 'ENSG00000169174'
        AND c."coloc_h4" > 0.8
        AND c."coloc_h3" < 0.02
        AND s."trait_reported" ILIKE '%cholesterol levels%'
        AND c."right_bio_feature" = 'IPSC'
        AND c."left_chrom" = '1'
        AND c."left_pos" = 55029009
        AND c."left_ref" = 'C'
        AND c."left_alt" = 'T'
),
stats AS (
    SELECT 
        ROUND(AVG(fd."coloc_log2_h4_h3"), 4) AS "average",
        ROUND(VAR_SAMP(fd."coloc_log2_h4_h3"), 4) AS "variance",
        ROUND(MAX(fd."coloc_log2_h4_h3") - MIN(fd."coloc_log2_h4_h3"), 4) AS "max_min_difference"
    FROM filtered_data fd
),
max_study AS (
    SELECT fd."right_study" AS "QTL_source"
    FROM filtered_data fd
    ORDER BY fd."coloc_log2_h4_h3" DESC NULLS LAST
    LIMIT 1
)
SELECT 
    stats."average",
    stats."variance",
    stats."max_min_difference",
    max_study."QTL_source"
FROM stats
CROSS JOIN max_study;