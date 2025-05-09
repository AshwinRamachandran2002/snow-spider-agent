WITH "impc_targets" AS (
    SELECT DISTINCT
        "targetId"
    FROM OPEN_TARGETS_PLATFORM_2.OPEN_TARGETS_PLATFORM."ASSOCIATIONBYDATASOURCEDIRECT"
    WHERE LOWER("datasourceId") = 'impc'
      AND "diseaseId" = 'EFO_0000676'
),
"scored" AS (
    SELECT
        o."targetId",
        o."score"
    FROM OPEN_TARGETS_PLATFORM_2.OPEN_TARGETS_PLATFORM."ASSOCIATIONBYOVERALLDIRECT" o
    JOIN "impc_targets" it
      ON it."targetId" = o."targetId"
    WHERE o."diseaseId" = 'EFO_0000676'
),
"max_score" AS (
    SELECT MAX("score") AS "max_score"
    FROM "scored"
)
SELECT DISTINCT
    t."approvedSymbol"
FROM OPEN_TARGETS_PLATFORM_2.OPEN_TARGETS_PLATFORM."TARGETS" t
JOIN "scored" s
  ON s."targetId" = t."id"
JOIN "max_score" m
  ON s."score" = m."max_score"
ORDER BY t."approvedSymbol";