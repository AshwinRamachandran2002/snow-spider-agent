SELECT 
    r."name"                               AS "reference_name",
    COUNT(*)                               AS "variant_count",
    r."length"                             AS "reference_length",
    COUNT(*)::FLOAT / r."length"           AS "variant_density"
FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_REFERENCE_201703 r
JOIN GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_201703 v
      ON r."name" = v."reference_name"
GROUP BY r."name", r."length"
ORDER BY "variant_density" DESC NULLS LAST, "reference_name"
LIMIT 1;