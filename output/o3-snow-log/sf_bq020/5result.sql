WITH variant_counts AS (
    SELECT 
        "reference_name",
        COUNT(*) AS "variant_count"
    FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS."MNPR01_201703"
    GROUP BY "reference_name"
)
SELECT 
    v."reference_name"
FROM variant_counts v
JOIN GENOMICS_CANNABIS.GENOMICS_CANNABIS."MNPR01_REFERENCE_201703" r
      ON v."reference_name" = r."name"
ORDER BY v."variant_count" / r."length" DESC NULLS LAST
LIMIT 1;