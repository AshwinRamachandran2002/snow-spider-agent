WITH impc_targets AS (
    SELECT DISTINCT ad."targetId"
    FROM OPEN_TARGETS_PLATFORM_2.OPEN_TARGETS_PLATFORM."ASSOCIATIONBYDATASOURCEDIRECT" ad
    WHERE ad."diseaseId" = 'EFO_0000676'
      AND UPPER(ad."datasourceId") = 'IMPC'
), scored_targets AS (
    SELECT ao."targetId",
           ao."score"
    FROM OPEN_TARGETS_PLATFORM_2.OPEN_TARGETS_PLATFORM."ASSOCIATIONBYOVERALLDIRECT" ao
    JOIN impc_targets it
      ON ao."targetId" = it."targetId"
    WHERE ao."diseaseId" = 'EFO_0000676'
), max_score AS (
    SELECT MAX("score") AS max_overall_score
    FROM scored_targets
)
SELECT t."approvedSymbol"
FROM scored_targets st
JOIN max_score ms
  ON st."score" = ms.max_overall_score
JOIN OPEN_TARGETS_PLATFORM_2.OPEN_TARGETS_PLATFORM."TARGETS" t
  ON t."id" = st."targetId"
ORDER BY t."approvedSymbol";