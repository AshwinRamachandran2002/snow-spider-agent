WITH filtered AS (
    SELECT
        od."targetId",
        od."score",
        MAX(od."score") OVER () AS "max_score"
    FROM OPEN_TARGETS_PLATFORM_2.OPEN_TARGETS_PLATFORM."ASSOCIATIONBYOVERALLDIRECT" od
    JOIN OPEN_TARGETS_PLATFORM_2.OPEN_TARGETS_PLATFORM."ASSOCIATIONBYDATASOURCEDIRECT" ad
          ON ad."targetId" = od."targetId"
         AND ad."diseaseId" = od."diseaseId"
    WHERE od."diseaseId" = 'EFO_0000676'
      AND LOWER(ad."datasourceId") = 'impc'
)
SELECT
    t."approvedSymbol"
FROM filtered f
JOIN OPEN_TARGETS_PLATFORM_2.OPEN_TARGETS_PLATFORM."TARGETS" t
      ON t."id" = f."targetId"
WHERE f."score" = f."max_score"
ORDER BY t."approvedSymbol";