WITH "filtered" AS (
    SELECT 
        "targetId",
        "score"
    FROM OPEN_TARGETS_PLATFORM_2.OPEN_TARGETS_PLATFORM."ASSOCIATIONBYDATASOURCEDIRECT"
    WHERE 
        "diseaseId" = 'EFO_0000676'
        AND UPPER("datasourceId") = 'IMPC'
),
"max_score" AS (
    SELECT MAX("score") AS "max_score"
    FROM "filtered"
)
SELECT 
    tgt."approvedSymbol"
FROM "filtered" f
JOIN "max_score" m
  ON f."score" = m."max_score"
JOIN OPEN_TARGETS_PLATFORM_2.OPEN_TARGETS_PLATFORM."TARGETS" tgt
  ON tgt."id" = f."targetId"
ORDER BY 
    tgt."approvedSymbol";