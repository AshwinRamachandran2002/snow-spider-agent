WITH trans_counts AS (
    SELECT 
        "reference_name",
        COUNT(*) AS "transcriptome_variants"
    FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS."MNPR01_TRANSCRIPTOME_201703"
    GROUP BY "reference_name"
),
genome_counts AS (
    SELECT 
        "reference_name",
        COUNT(*) AS "genome_variants"
    FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS."MNPR01_201703"
    GROUP BY "reference_name"
),
combined AS (
    SELECT 
        COALESCE(t."reference_name", g."reference_name")          AS "reference_name",
        COALESCE(t."transcriptome_variants", 0)                   AS "transcriptome_variants",
        COALESCE(g."genome_variants", 0)                          AS "genome_variants"
    FROM trans_counts t
    FULL OUTER JOIN genome_counts g
        ON t."reference_name" = g."reference_name"
),
density AS (
    SELECT 
        r."name"                                                  AS "reference_name",
        r."length",
        (c."transcriptome_variants" + c."genome_variants")        AS "total_variants",
        (c."transcriptome_variants" + c."genome_variants") / r."length" AS "variant_density"
    FROM combined c
    JOIN GENOMICS_CANNABIS.GENOMICS_CANNABIS."MNPR01_REFERENCE_201703" r
        ON r."name" = c."reference_name"
)
SELECT 
    "reference_name"
FROM density
ORDER BY "variant_density" DESC NULLS LAST
LIMIT 1;