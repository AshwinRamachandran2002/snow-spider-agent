WITH psoriasis_scores AS (
    SELECT a."targetId",
           a."score"
    FROM OPEN_TARGETS_PLATFORM_1.PLATFORM.ASSOCIATIONBYOVERALLDIRECT a
    JOIN OPEN_TARGETS_PLATFORM_1.PLATFORM.DISEASES d
          ON a."diseaseId" = d."id"
    WHERE LOWER(d."name") = 'psoriasis'
),
mean_score AS (
    SELECT AVG("score") AS mean_sc
    FROM psoriasis_scores
),
closest AS (
    SELECT ps."targetId",
           ps."score",
           ABS(ps."score" - ms.mean_sc) AS diff
    FROM psoriasis_scores ps
    CROSS JOIN mean_score ms
    ORDER BY diff ASC NULLS LAST
    LIMIT 1
)
SELECT t."approvedSymbol"
FROM closest c
JOIN OPEN_TARGETS_PLATFORM_1.PLATFORM.TARGETS t
     ON c."targetId" = t."id";