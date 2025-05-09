WITH variant_counts AS (
    SELECT 
        "reference_name",
        COUNT(*) AS "variant_count"
    FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_TRANSCRIPTOME_201703
    GROUP BY "reference_name"
)
SELECT 
    r."name"
FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_REFERENCE_201703 r
JOIN variant_counts v
      ON r."name" = v."reference_name"
ORDER BY v."variant_count" / r."length" DESC NULLS LAST, r."name"
LIMIT 1;