WITH psoriasis_disease AS (
    SELECT "id"
    FROM OPEN_TARGETS_PLATFORM_1.PLATFORM.DISEASES
    WHERE LOWER("name") = 'psoriasis'
), 
psoriasis_assoc AS (
    SELECT a."targetId",
           a."score"
    FROM OPEN_TARGETS_PLATFORM_1.PLATFORM.ASSOCIATIONBYOVERALLDIRECT a
    JOIN psoriasis_disease d
      ON a."diseaseId" = d."id"
), 
mean_score AS (
    SELECT AVG("score") AS avg_score
    FROM psoriasis_assoc
), 
closest AS (
    SELECT pa."targetId",
           pa."score",
           ABS(pa."score" - ms.avg_score) AS diff
    FROM psoriasis_assoc pa
    CROSS JOIN mean_score ms
    ORDER BY diff ASC
    LIMIT 1
)
SELECT t."approvedSymbol"
FROM closest c
JOIN OPEN_TARGETS_PLATFORM_1.PLATFORM.TARGETS t
  ON t."id" = c."targetId";