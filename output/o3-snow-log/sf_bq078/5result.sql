WITH "IMPC_ASSOCIATIONS" AS (
    SELECT 
        "targetId",
        "score"
    FROM OPEN_TARGETS_PLATFORM_2.OPEN_TARGETS_PLATFORM."ASSOCIATIONBYDATASOURCEDIRECT"
    WHERE 
        "diseaseId" = 'EFO_0000676'
        AND LOWER("datasourceId") = 'impc'
), "MAX_SCORE" AS (
    SELECT 
        MAX("score") AS "max_score"
    FROM "IMPC_ASSOCIATIONS"
)
SELECT DISTINCT
    t."approvedSymbol"
FROM "IMPC_ASSOCIATIONS" a
JOIN "MAX_SCORE" m
    ON a."score" = m."max_score"
JOIN OPEN_TARGETS_PLATFORM_2.OPEN_TARGETS_PLATFORM."TARGETS" t
    ON t."id" = a."targetId"
ORDER BY
    t."approvedSymbol";