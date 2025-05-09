WITH impc_targets AS (
    SELECT DISTINCT
           "targetId",
           "diseaseId"
    FROM OPEN_TARGETS_PLATFORM_2.OPEN_TARGETS_PLATFORM."ASSOCIATIONBYDATASOURCEDIRECT"
    WHERE "diseaseId" = 'EFO_0000676'
      AND UPPER("datasourceId") = 'IMPC'
),
scored_targets AS (
    SELECT
        it."targetId",
        od."score"
    FROM impc_targets it
    JOIN OPEN_TARGETS_PLATFORM_2.OPEN_TARGETS_PLATFORM."ASSOCIATIONBYOVERALLDIRECT" od
      ON od."targetId" = it."targetId"
     AND od."diseaseId" = it."diseaseId"
),
max_score AS (
    SELECT MAX("score") AS "max_score"
    FROM scored_targets
)
SELECT DISTINCT
       tg."approvedSymbol"
FROM scored_targets st
JOIN max_score ms
  ON st."score" = ms."max_score"
JOIN OPEN_TARGETS_PLATFORM_2.OPEN_TARGETS_PLATFORM."TARGETS" tg
  ON tg."id" = st."targetId"
ORDER BY tg."approvedSymbol";