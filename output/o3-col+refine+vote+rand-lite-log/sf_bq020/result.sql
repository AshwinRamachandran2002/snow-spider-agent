WITH genomic AS (
    SELECT "reference_name",
           COUNT(*) AS "g_variants"
    FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_201703
    GROUP BY "reference_name"
),
transcriptome AS (
    SELECT "reference_name",
           COUNT(*) AS "t_variants"
    FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_TRANSCRIPTOME_201703
    GROUP BY "reference_name"
),
total_variants AS (
    SELECT COALESCE(g."reference_name", t."reference_name")     AS "reference_name",
           COALESCE(g."g_variants", 0) + COALESCE(t."t_variants", 0) AS "variant_count"
    FROM genomic g
    FULL OUTER JOIN transcriptome t
        ON g."reference_name" = t."reference_name"
),
variant_density AS (
    SELECT r."name",
           r."length",
           tv."variant_count",
           tv."variant_count" / r."length" AS "variant_density"
    FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_REFERENCE_201703 r
    JOIN total_variants tv
        ON r."name" = tv."reference_name"
)
SELECT "name"
FROM variant_density
ORDER BY "variant_density" DESC NULLS LAST
LIMIT 1;