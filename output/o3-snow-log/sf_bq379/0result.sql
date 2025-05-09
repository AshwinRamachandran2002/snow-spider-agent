WITH psoriasis_id AS (
    SELECT "id"
    FROM OPEN_TARGETS_PLATFORM_1.PLATFORM.DISEASES
    WHERE LOWER("name") = 'psoriasis'
),
psoriasis_scores AS (
    SELECT ad."targetId",
           ad."score"
    FROM OPEN_TARGETS_PLATFORM_1.PLATFORM.ASSOCIATIONBYOVERALLDIRECT ad
    JOIN psoriasis_id p
      ON ad."diseaseId" = p."id"
),
mean_val AS (
    SELECT AVG("score") AS mean_score
    FROM psoriasis_scores
),
diffs AS (
    SELECT ps."targetId",
           ps."score",
           ABS(ps."score" - mv.mean_score) AS diff_from_mean
    FROM psoriasis_scores ps,
         mean_val mv
),
closest_target AS (
    SELECT *
    FROM diffs
    ORDER BY diff_from_mean ASC
    LIMIT 1
)
SELECT t."approvedSymbol"
FROM closest_target ct
JOIN OPEN_TARGETS_PLATFORM_1.PLATFORM.TARGETS t
  ON t."id" = ct."targetId";