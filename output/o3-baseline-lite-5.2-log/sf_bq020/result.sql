WITH variant_counts AS (
    SELECT 
        "reference_name",
        COUNT(*) AS "variant_count"
    FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS."MNPR01_201703"
    GROUP BY "reference_name"
),
density_calcs AS (
    SELECT 
        r."name"          AS "reference_name",
        r."length",
        COALESCE(vc."variant_count",0)                             AS "variant_count",
        (COALESCE(vc."variant_count",0)::FLOAT / r."length")       AS "variant_density"
    FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS."MNPR01_REFERENCE_201703" r
    LEFT JOIN variant_counts vc
           ON vc."reference_name" = r."name"
)
SELECT "reference_name"
FROM density_calcs
ORDER BY "variant_density" DESC NULLS LAST, "reference_name"
LIMIT 1;