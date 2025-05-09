WITH genomic AS (
    SELECT "reference_name",
           COUNT(*) AS "g_cnt"
    FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_201703
    GROUP BY "reference_name"
),
transcriptome AS (
    SELECT "reference_name",
           COUNT(*) AS "t_cnt"
    FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_TRANSCRIPTOME_201703
    GROUP BY "reference_name"
),
combined AS (
    SELECT COALESCE(genomic."reference_name", transcriptome."reference_name") AS "reference_name",
           COALESCE(genomic."g_cnt", 0) + COALESCE(transcriptome."t_cnt", 0) AS "total_variants"
    FROM genomic
    FULL JOIN transcriptome
      ON genomic."reference_name" = transcriptome."reference_name"
)
SELECT r."name" AS "reference_sequence_with_highest_density"
FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_REFERENCE_201703 r
JOIN combined c
  ON r."name" = c."reference_name"
ORDER BY (c."total_variants" / r."length") DESC NULLS LAST
LIMIT 1;