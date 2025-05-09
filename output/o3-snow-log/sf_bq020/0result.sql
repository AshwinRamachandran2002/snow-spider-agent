WITH transcriptome_cnt AS (
    SELECT "reference_name",
           COUNT(*) AS "var_cnt"
    FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS."MNPR01_TRANSCRIPTOME_201703"
    GROUP BY "reference_name"
),
genome_cnt AS (
    SELECT "reference_name",
           COUNT(*) AS "var_cnt"
    FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS."MNPR01_201703"
    GROUP BY "reference_name"
),
all_variants AS (
    SELECT "reference_name", "var_cnt" FROM transcriptome_cnt
    UNION ALL
    SELECT "reference_name", "var_cnt" FROM genome_cnt
),
total_per_ref AS (
    SELECT "reference_name",
           SUM("var_cnt") AS "total_variants"
    FROM all_variants
    GROUP BY "reference_name"
)
SELECT r."name" AS "reference_name_with_highest_variant_density"
FROM total_per_ref t
JOIN GENOMICS_CANNABIS.GENOMICS_CANNABIS."MNPR01_REFERENCE_201703" r
      ON r."name" = t."reference_name"
ORDER BY (t."total_variants"::FLOAT / r."length") DESC NULLS LAST
LIMIT 1;