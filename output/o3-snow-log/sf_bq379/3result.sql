WITH psoriasis_scores AS (
    SELECT
        a."targetId",
        a."score"
    FROM OPEN_TARGETS_PLATFORM_1.PLATFORM.ASSOCIATIONBYOVERALLDIRECT a
    WHERE a."diseaseId" = 'EFO_0000676'      -- psoriasis
),
mean_score AS (
    SELECT AVG("score") AS mean_val
    FROM psoriasis_scores
),
closest_to_mean AS (
    SELECT
        p."targetId",
        p."score",
        ABS(p."score" - m.mean_val) AS diff_to_mean
    FROM psoriasis_scores p
    CROSS JOIN mean_score m
    ORDER BY diff_to_mean ASC NULLS LAST, p."targetId"
    LIMIT 1
)
SELECT
    t."approvedSymbol"
FROM closest_to_mean c
JOIN OPEN_TARGETS_PLATFORM_1.PLATFORM.TARGETS t
  ON t."id" = c."targetId";