WITH genomic_variants AS (
    SELECT "reference_name",
           COUNT(*) AS variant_count
    FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_201703
    GROUP BY "reference_name"
),
transcriptome_variants AS (
    SELECT "reference_name",
           COUNT(*) AS variant_count
    FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_TRANSCRIPTOME_201703
    GROUP BY "reference_name"
),
all_variants AS (
    SELECT COALESCE(g."reference_name", t."reference_name")            AS "reference_name",
           COALESCE(g.variant_count, 0) + COALESCE(t.variant_count, 0) AS total_variants
    FROM genomic_variants g
    FULL JOIN transcriptome_variants t
           ON g."reference_name" = t."reference_name"
)
SELECT r."name" AS "reference_sequence_name"
FROM   GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_REFERENCE_201703 r
JOIN   all_variants v
       ON r."name" = v."reference_name"
ORDER BY v.total_variants / r."length"::FLOAT DESC NULLS LAST
LIMIT 1;