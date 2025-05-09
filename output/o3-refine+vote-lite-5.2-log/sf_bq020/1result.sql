WITH variants_per_ref AS (
    SELECT 
        v."reference_name"                           AS ref_name,
        COUNT(*)                                     AS variant_count
    FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_TRANSCRIPTOME_201703 v
    GROUP BY v."reference_name"
), density AS (
    SELECT
        r."name"                                     AS ref_name,
        r."length"                                   AS seq_length,
        COALESCE(v.variant_count, 0)                 AS variant_count,
        COALESCE(v.variant_count, 0)::FLOAT / r."length" AS variant_density
    FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_REFERENCE_201703 r
    LEFT JOIN variants_per_ref v
        ON r."name" = v.ref_name
)
SELECT 
    ref_name
FROM density
ORDER BY variant_density DESC NULLS LAST, ref_name
LIMIT 1;