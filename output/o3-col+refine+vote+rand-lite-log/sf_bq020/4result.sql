SELECT
    c."reference_name"
FROM (
    SELECT
        "reference_name",
        COUNT(*) AS "variant_count"
    FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_TRANSCRIPTOME_201703
    GROUP BY "reference_name"
) AS c
JOIN GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_REFERENCE_201703 AS r
  ON c."reference_name" = r."name"
ORDER BY (c."variant_count" / NULLIF(r."length",0)) DESC NULLS LAST
LIMIT 1;