WITH all_variants AS (
    SELECT "reference_name"
    FROM   "GENOMICS_CANNABIS"."GENOMICS_CANNABIS"."MNPR01_201703"
    UNION ALL
    SELECT "reference_name"
    FROM   "GENOMICS_CANNABIS"."GENOMICS_CANNABIS"."MNPR01_TRANSCRIPTOME_201703"
)
SELECT   r."name" AS "reference_sequence_name"
FROM     all_variants a
JOIN     "GENOMICS_CANNABIS"."GENOMICS_CANNABIS"."MNPR01_REFERENCE_201703" r
       ON a."reference_name" = r."name"
GROUP BY r."name", r."length"
ORDER BY COUNT(*) / r."length" DESC NULLS LAST
LIMIT 1;