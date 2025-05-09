WITH TargetScores AS (
    SELECT "targetId", "score"
    FROM OPEN_TARGETS_PLATFORM_1.PLATFORM.ASSOCIATIONBYOVERALLDIRECT
    WHERE "diseaseId" = 'EFO_0000676'
),
MeanScore AS (
    SELECT AVG("score") AS "mean_score"
    FROM TargetScores
)
SELECT T."approvedSymbol" AS "approved_symbol", ROUND(TS."score", 4) AS "association_score"
FROM TargetScores TS
CROSS JOIN MeanScore
JOIN OPEN_TARGETS_PLATFORM_1.PLATFORM.TARGETS T ON T."id" = TS."targetId"
ORDER BY ABS(TS."score" - MeanScore."mean_score") ASC, T."approvedSymbol"
LIMIT 1