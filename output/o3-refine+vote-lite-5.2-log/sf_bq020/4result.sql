WITH variant_counts AS (
    SELECT 
        "reference_name",
        COUNT(*) AS "variant_count"
    FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_TRANSCRIPTOME_201703
    GROUP BY "reference_name"
)
SELECT 
    ref."name"
FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_REFERENCE_201703 AS ref
JOIN variant_counts vc
      ON ref."name" = vc."reference_name"
ORDER BY (vc."variant_count"::FLOAT / ref."length") DESC NULLS LAST
LIMIT 1;