WITH genome AS (
    SELECT 
        "reference_name", 
        COUNT(*) AS "g_cnt"
    FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_201703
    GROUP BY "reference_name"
), 
transcriptome AS (
    SELECT 
        "reference_name", 
        COUNT(*) AS "t_cnt"
    FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_TRANSCRIPTOME_201703
    GROUP BY "reference_name"
), 
combined AS (
    SELECT 
        COALESCE(g."reference_name", t."reference_name") AS "reference_name",
        COALESCE(g."g_cnt", 0) + COALESCE(t."t_cnt", 0)  AS "total_variants"
    FROM genome g
    FULL JOIN transcriptome t
        ON g."reference_name" = t."reference_name"
)
SELECT 
    r."name" AS "highest_density_reference"
FROM combined c
JOIN GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_REFERENCE_201703 r
    ON r."name" = c."reference_name"
ORDER BY 
    c."total_variants" / (r."length" / 1000.0) DESC NULLS LAST
LIMIT 1;