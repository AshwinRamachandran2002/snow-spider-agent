SELECT 
    ref."name"
FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_REFERENCE_201703 AS ref
JOIN GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_201703          AS var
  ON var."reference_name" = ref."name"
GROUP BY 
    ref."name",
    ref."length"
ORDER BY 
    COUNT(*)::FLOAT / NULLIF(ref."length", 0) DESC NULLS LAST,
    ref."name"
LIMIT 1;