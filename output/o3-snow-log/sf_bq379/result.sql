WITH
psoriasis_scores AS (
    SELECT
        "targetId",
        "score"
    FROM OPEN_TARGETS_PLATFORM_1.PLATFORM.ASSOCIATIONBYOVERALLDIRECT
    WHERE "diseaseId" = 'EFO_0000676'          -- psoriasis
),
mean_score AS (
    SELECT AVG("score") AS avg_score
    FROM psoriasis_scores
),
closest_target AS (
    SELECT
        p."targetId",
        p."score",
        ABS(p."score" - m.avg_score) AS diff
    FROM psoriasis_scores p
    CROSS JOIN mean_score m
    ORDER BY diff ASC NULLS LAST
    LIMIT 1
)
SELECT
    t."approvedSymbol"
FROM closest_target c
JOIN OPEN_TARGETS_PLATFORM_1.PLATFORM.TARGETS t
  ON t."id" = c."targetId";