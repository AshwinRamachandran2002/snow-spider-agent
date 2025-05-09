SELECT c."reference_name"
FROM (
    SELECT "reference_name",
           COUNT(*) AS "variant_count"
    FROM "GENOMICS_CANNABIS"."GENOMICS_CANNABIS"."MNPR01_201703"
    GROUP BY "reference_name"
) c
JOIN "GENOMICS_CANNABIS"."GENOMICS_CANNABIS"."MNPR01_REFERENCE_201703" r
      ON c."reference_name" = r."name"
WHERE r."length" > 0
ORDER BY c."variant_count" / r."length" DESC NULLS LAST
LIMIT 1;