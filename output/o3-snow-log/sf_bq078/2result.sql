WITH "impc_targets" AS (
    SELECT DISTINCT "targetId"
    FROM OPEN_TARGETS_PLATFORM_2.OPEN_TARGETS_PLATFORM."ASSOCIATIONBYDATASOURCEDIRECT"
    WHERE "diseaseId" = 'EFO_0000676'
      AND LOWER("datasourceId") = 'impc'
),
"overall_scores" AS (
    SELECT ao."targetId",
           ao."score"
    FROM OPEN_TARGETS_PLATFORM_2.OPEN_TARGETS_PLATFORM."ASSOCIATIONBYOVERALLDIRECT" ao
    JOIN "impc_targets" it
      ON ao."targetId" = it."targetId"
    WHERE ao."diseaseId" = 'EFO_0000676'
),
"max_score" AS (
    SELECT MAX("score") AS "max_score"
    FROM "overall_scores"
)
SELECT DISTINCT t."approvedSymbol"
FROM "overall_scores" os
JOIN "max_score" ms
  ON os."score" = ms."max_score"
JOIN OPEN_TARGETS_PLATFORM_2.OPEN_TARGETS_PLATFORM."TARGETS" t
  ON t."id" = os."targetId"
ORDER BY t."approvedSymbol";