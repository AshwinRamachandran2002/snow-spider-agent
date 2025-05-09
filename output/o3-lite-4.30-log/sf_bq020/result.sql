SELECT
    r."name" AS reference_sequence_name
FROM "GENOMICS_CANNABIS"."GENOMICS_CANNABIS"."MNPR01_REFERENCE_201703" r
LEFT JOIN "GENOMICS_CANNABIS"."GENOMICS_CANNABIS"."MNPR01_201703" v
       ON r."name" = v."reference_name"
GROUP BY r."name", r."length"
ORDER BY COUNT(v."reference_name") / r."length"::FLOAT DESC NULLS LAST, r."name"
LIMIT 1;