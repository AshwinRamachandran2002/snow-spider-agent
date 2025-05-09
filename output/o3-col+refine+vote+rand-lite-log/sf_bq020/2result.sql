WITH transcriptome_counts AS (
    SELECT 
        "reference_name",
        COUNT(*) AS "count_t"
    FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_TRANSCRIPTOME_201703
    GROUP BY "reference_name"
),
dna_counts AS (
    SELECT 
        "reference_name",
        COUNT(*) AS "count_d"
    FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_201703
    GROUP BY "reference_name"
),
combined_counts AS (
    SELECT 
        COALESCE(t."reference_name", d."reference_name")       AS "reference_name",
        COALESCE(t."count_t", 0) + COALESCE(d."count_d", 0)    AS "total_variant_count"
    FROM transcriptome_counts t
    FULL OUTER JOIN dna_counts d
        ON t."reference_name" = d."reference_name"
)
SELECT 
    c."reference_name"
FROM combined_counts c
JOIN GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_REFERENCE_201703 r
    ON c."reference_name" = r."name"
ORDER BY c."total_variant_count" / r."length" DESC NULLS LAST
LIMIT 1;