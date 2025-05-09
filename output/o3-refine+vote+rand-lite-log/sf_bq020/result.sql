SELECT
    r."name"
FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_201703           AS v
JOIN GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_REFERENCE_201703 AS r
      ON v."reference_name" = r."name"
GROUP BY
    r."name",
    r."length"
ORDER BY
    COUNT(*) / r."length" DESC NULLS LAST,
    r."name"
LIMIT 1;